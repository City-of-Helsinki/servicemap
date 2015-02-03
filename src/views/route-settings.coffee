define ->

    class RouteSettingsView extends base.SMLayout
        template: 'route-settings'
        regions:
            'header_region': '.route-settings-header'
            'route_controllers_region': '.route-controllers'
            'accessibility_summary_region': '.accessibility-viewpoint-part'
            'transport_mode_controls_region': '.transport_mode_controls'

        initialize: (attrs) ->
            @unit = attrs.unit
            @user_click_coordinate_position = attrs.user_click_coordinate_position
            @listenTo @model, 'change', @update_regions

        onRender: ->
            @header_region.show new RouteSettingsHeaderView
                model: @model
            @route_controllers_region.show new RouteControllersView
                model: @model
                unit: @unit
                user_click_coordinate_position: @user_click_coordinate_position
            @accessibility_summary_region.show new AccessibilityViewpointView
                filter_transit: true
                template: 'accessibility-viewpoint-oneline'
            @transport_mode_controls_region.show new TransportModeControlsView

        update_regions: ->
            @header_region.currentView.render()
            @accessibility_summary_region.currentView.render()
            @transport_mode_controls_region.currentView.render()


    class RouteSettingsHeaderView extends base.SMItemView
        template: 'route-settings-header'
        events:
            'click .settings-summary': 'toggle_settings_visibility'
            'click .ok-button': 'toggle_settings_visibility'

        serializeData: ->
            profiles = p13n.get_accessibility_profile_ids true

            origin = @model.get_origin()
            origin_name = @model.get_endpoint_name origin
            if (
                (origin?.is_detected_location() and not origin?.is_pending()) or
                (origin? and origin instanceof models.CoordinatePosition)
            )
                origin_name = origin_name.toLowerCase()

            transport_icons = []
            for mode, value of p13n.get('transport')
                if value
                    transport_icons.push "icon-icon-#{mode.replace('_', '-')}"

            profile_set: _.keys(profiles).length
            profiles: p13n.get_profile_elements profiles
            origin_name: origin_name
            origin_is_pending: @model.get_origin().is_pending()
            transport_icons: transport_icons

        toggle_settings_visibility: (event) ->
            event.preventDefault()
            $('#route-details').toggleClass('settings-open')


    class TransportModeControlsView extends base.SMItemView
        template: 'transport-mode-controls'
        events:
            'click .transport-modes a': 'switch_transport_mode'
            'click .transport-details a': 'switch_transport_details'

        serializeData: ->
            transport_modes = p13n.get('transport')
            bicycle_details_classes = ''
            if transport_modes.public_transport
                bicycle_details_classes += 'no-arrow '
            unless transport_modes.bicycle
                bicycle_details_classes += 'hidden'

            transport_modes: transport_modes
            transport_details: p13n.get('transport_details')
            bicycle_details_classes: bicycle_details_classes

        switch_transport_mode: (ev) ->
            ev.preventDefault()
            type = $(ev.target).closest('li').data 'type'
            p13n.toggle_transport type

        switch_transport_details: (ev) ->
            ev.preventDefault()
            type = $(ev.target).closest('li').data 'type'
            p13n.toggle_transport_details type


    class RouteControllersView extends base.SMItemView
        template: 'route-controllers'
        events:
            'click .preset.unlocked': 'switch_to_location_input'
            'click .preset-current-time': 'switch_to_time_input'
            'click .preset-current-date': 'switch_to_date_input'
            'click .time-mode': 'set_time_mode'
            'click .swap-endpoints': 'swap_endpoints'
            'click': 'undo_changes'
            # Important: the above click handler requires the following
            # to not disable the time picker widget.
            'click .time': (ev) -> ev.stopPropagation()
            'click .date': (ev) -> ev.stopPropagation()

        initialize: (attrs) ->
            window.debug_routing_controls = @
            @permanentModel = @model
            @current_unit = attrs.unit
            @user_click_coordinate_position = attrs.user_click_coordinate_position
            @_reset()

        _reset: ->
            @stopListening @model
            @model = @permanentModel.clone()
            @listenTo @model, 'change', (model, options) =>
                # If the change was an interaction with the datetimepicker
                # widget, we shouldn't re-render.
                unless options?.already_visible
                    @$el.find('input.time').data("DateTimePicker")?.hide()
                    @$el.find('input.time').data("DateTimePicker")?.destroy()
                    @$el.find('input.date').data("DateTimePicker")?.hide()
                    @$el.find('input.date').data("DateTimePicker")?.destroy()
                    @render()
            @listenTo @model.get_origin(), 'change', @render
            @listenTo @model.get_destination(), 'change', @render

        onRender: ->
            @enable_typeahead '.transit-end input'
            @enable_typeahead '.transit-start input'
            @enable_datetime_picker()

        enable_datetime_picker: ->
            keys = ['time', 'date']
            other = (key) =>
                keys[keys.indexOf(key) % keys.length]
            input_element = (key) =>
                @$el.find "input.#{key}"
            other_hider = (key) => =>
                input_element(other(key)).data("DateTimePicker")?.hide()
            value_setter = (key) => (ev) =>
                @model["set_#{key}"].call @model, ev.date.toDate(),
                    already_visible: true
                @apply_changes()

            for key in keys
                $input = input_element key
                if $input.length > 0
                    options = {}
                    disable_pick = switch key
                        when 'time' then 'pickDate'
                        when 'date' then 'pickTime'
                    options[disable_pick] = false
                    $input.datetimepicker options
                    $input.on 'dp.show', other_hider()
                    $input.on 'dp.change', value_setter(key)
                    if @activate_on_render == "#{key}_input"
                        $input.data("DateTimePicker").show()
            @activate_on_render = null

        apply_changes: ->
            @permanentModel.set @model.attributes
            @permanentModel.trigger_complete()
        undo_changes: ->
            @_reset()
            origin = @model.get_origin()
            destination = @model.get_destination()
            if origin instanceof models.CoordinatePosition
                @user_click_coordinate_position.wrap origin
            else if destination instanceof models.CoordinatePosition
                @user_click_coordinate_position.wrap destination
            @model.trigger 'change'

        enable_typeahead: (selector) ->
            @$search_el = @$el.find selector
            unless @$search_el.length
                return
            address_dataset =
                source: search.geocoder_engine.ttAdapter(),
                displayKey: (c) -> c.name
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> ctx.name

            @$search_el.typeahead null, [address_dataset]

            select_address = (event, match) =>
                @commit = true
                address_position = new models.AddressPosition match

                switch $(event.currentTarget).attr 'data-endpoint'
                    when 'origin'
                        @model.set_origin address_position
                    when 'destination'
                        @model.set_destination address_position

                @apply_changes()

            @$search_el.on 'typeahead:selected', (event, match) =>
                select_address event, match
            @$search_el.on 'typeahead:autocompleted', (event, match) =>
                select_address event, match
            @$search_el.keydown (ev) =>
                if ev.keyCode == 9 # tabulator
                    @undo_changes()
            # TODO figure out why focus doesn't work
            @$search_el.focus()

        _location_name_and_locking: (object) ->
            name: @model.get_endpoint_name object
            lock: @model.get_endpoint_locking object

        serializeData: ->
            datetime = moment @model.get_datetime()
            today = new Date()
            tomorrow = moment(today).add 1, 'days'
            is_today: not @force_date_input and datetime.isSame(today, 'day')
            is_tomorrow: datetime.isSame tomorrow, 'day'
            params: @model
            origin: @_location_name_and_locking @model.get_origin()
            destination: @_location_name_and_locking @model.get_destination()
            time: datetime.format 'LT'
            date: datetime.format 'L'
            time_mode: @model.get 'time_mode'

        swap_endpoints: (ev) ->
            ev.stopPropagation()
            @permanentModel.swap_endpoints
                silent: true
            @model.swap_endpoints()
            if @model.is_complete()
                @apply_changes()

        switch_to_location_input: (ev) ->
            ev.stopPropagation()
            @_reset()
            position = new models.CoordinatePosition
                is_detected: false
            @user_click_coordinate_position.wrap position
            switch $(ev.currentTarget).attr 'data-route-node'
                when 'start' then @model.set_origin position
                when 'end' then @model.set_destination position
            @listenTo position, 'change', =>
                @apply_changes()
                @render()
            position.trigger 'request'

        set_time_mode: (ev) ->
            ev.stopPropagation()
            time_mode = $(ev.target).data('value')
            if time_mode != @model.get 'time_mode'
                @model.set_time_mode(time_mode)
                @apply_changes()

        switch_to_time_input: (ev) ->
            ev.stopPropagation()
            @activate_on_render = 'time_input'
            @model.set_default_datetime()
        switch_to_date_input: (ev) ->
            ev.stopPropagation()
            @activate_on_render = 'date_input'
            @force_date_input = true
            @model.trigger 'change'
