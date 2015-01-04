define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'moment', 'bootstrap-datetimepicker', 'typeahead.bundle', 'raven', 'app/p13n', 'app/widgets', 'app/jade', 'app/models', 'app/search', 'app/color', 'app/draw', 'app/transit', 'app/animations', 'app/accessibility', 'app/accessibility_sentences', 'app/sidebar-region', 'app/spinner', 'app/dateformat'], (_, Backbone, Marionette, Leaflet, i18n, moment, datetimepicker, typeahead, Raven, p13n, widgets, jade, models, search, colors, draw, transit, animations, accessibility, accessibility_sentences, SidebarRegion, SMSpinner, dateformat) ->

    PAGE_SIZE = 200
    MOBILE_UI_BREAKPOINT = 768 # Mobile UI is used below this screen width.

    mixOf = (base, mixins...) ->
        class Mixed extends base
        for mixin in mixins by -1 #earlier mixins override later ones
            for name, method of mixin::
                Mixed::[name] = method
        Mixed

    class SMTemplateMixin
        mixinTemplateHelpers: (data) ->
            jade.mixin_helpers data
            return data
        getTemplate: ->
            return jade.get_template @template

    class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin
    class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin
    class SMCompositeView extends mixOf Marionette.CompositeView, SMTemplateMixin
    class SMLayout extends mixOf Marionette.Layout, SMTemplateMixin

    class TitleView extends SMItemView
        className:
            'title-control'
        render: =>
            @el.innerHTML = jade.template 'title-view', lang: p13n.get_language(), root: app_settings.url_prefix

    class LandingTitleView extends SMItemView
        template: 'landing-title-view'
        id: 'title'
        className: 'landing-title-control'
        initialize: ->
            @listenTo(app.vent, 'title-view:hide', @hideTitleView)
            @listenTo(app.vent, 'title-view:show', @unHideTitleView)
        serializeData: ->
            isHidden: @isHidden
            lang: p13n.get_language()
        hideTitleView: ->
            $('body').removeClass 'landing'
            @isHidden = true
            @render()
        unHideTitleView: ->
            $('body').addClass 'landing'
            @isHidden = false
            @render()

    class BrowseButtonView extends SMItemView
        template: 'navigation-browse'
    class SearchInputView extends SMItemView
        classname: 'search-input-element'
        template: 'navigation-search'
        initialize: (@model, @search_results) ->
            @listenTo @model, 'change:input_query', @adapt_to_query
            @listenTo @search_results, 'ready', @adapt_to_query
        adapt_to_query: (model, value, opts) ->
            $container = @$el.find('.action-button')
            $icon = $container.find('span')
            if opts? and (opts.initial or opts.clearing)
                @$search_el.val @model.get('input_query')
            if @is_empty()
                if @search_results.query
                    if opts? and opts.initial
                        @model.set 'input_query', @search_results.query,
                            initial: false
            if @is_empty() or @model.get('input_query') == @search_results.query
                $icon.removeClass 'icon-icon-forward-bold'
                $icon.addClass 'icon-icon-close'
                $container.removeClass 'search-button'
                $container.addClass 'close-button'
            else
                $icon.addClass 'icon-icon-forward-bold'
                $icon.removeClass 'icon-icon-close'
                $container.removeClass 'close-button'
                $container.addClass 'search-button'
        events:
            'typeahead:selected': 'autosuggest_show_details'
            # Important! The following ensures the click
            # will only cause the intended typeahead selection.
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click .typeahead-suggestion.fulltext': 'execute_query'
            'click .action-button.search-button': 'search'

        search: (e) ->
            e.stopPropagation()
            unless @is_empty()
                @execute_query()

        is_empty: () ->
            query = @model.get 'input_query'
            if query? and query.length > 0
                return false
            return true
        onRender: () ->
            @enable_typeahead('input.form-control[type=search]')
            @set_typeahead_width()
            $(window).resize => @set_typeahead_width()
        set_typeahead_width: ->
            windowWidth = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
            if windowWidth < MOBILE_UI_BREAKPOINT
                width = $('#navigation-header').width()
                @$el.find('.tt-dropdown-menu').css 'width': width
            else
                @$el.find('.tt-dropdown-menu').css 'width': 'auto'
        enable_typeahead: (selector) ->
            @$search_el = @$el.find selector
            service_dataset =
                name: 'service'
                source: search.servicemap_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
            event_dataset =
                name: 'event'
                source: search.linkedevents_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
            address_dataset =
                source: search.geocoder_engine.ttAdapter(),
                displayKey: (c) -> c.name
                templates:
                    suggestion: (ctx) ->
                        ctx.object_type = 'address'
                        jade.template 'typeahead-suggestion', ctx

            # A hack needed to ensure the header is always rendered.
            full_dataset =
                name: 'header'
                # Source has to return non-empty list
                source: (q, c) -> c([{query: q, object_type: 'query'}])
                displayKey: (s) -> s.query
                name: 'full'
                templates:
                    suggestion: (s) -> jade.template 'typeahead-fulltext', s

            @$search_el.typeahead null, [full_dataset, address_dataset, service_dataset, event_dataset]

            # On enter: was there a selection from the autosuggestions
            # or did the user hit enter without having selected a
            # suggestion?
            selected = false
            @$search_el.on 'typeahead:selected', (ev) =>
                selected = true
            @$search_el.on 'input', (ev) =>
                query = @get_query()
                @model.set 'input_query', query,
                    initial: false,
                    keep_open: true
                @search_results.trigger 'hide'

            @$search_el.keyup (ev) =>
                # Handle enter
                if ev.keyCode != 13
                    selected = false
                    return
                else if selected
                    # Skip autosuggestion selection with keyboard
                    selected = false
                    return
                @execute_query()
        get_query: () ->
            return $.trim @$search_el.val()
        execute_query: () ->
            @$search_el.typeahead 'close'
            app.commands.execute 'search', @model.get 'input_query'
        autosuggest_show_details: (ev, data, _) ->
            @$search_el.typeahead 'val', ''
            @model.set 'input_query', null
            app.commands.execute 'clearSearchResults'
            $('.search-container input').val('')
            # Remove focus from the search box to hide keyboards on touch devices.
            $('.search-container input').blur()
            model = null
            object_type = data.object_type
            switch object_type
                when 'unit'
                    model = new models.Unit(data)
                    app.commands.execute 'setUnit', model
                    app.commands.execute 'selectUnit', model
                when 'service'
                    app.commands.execute 'addService',
                        new models.Service(data)
                when 'event'
                    app.commands.execute 'selectEvent',
                        new models.Event(data)
                when 'query'
                    app.commands.execute 'search', data.query
                when 'address'
                    app.commands.execute 'selectPosition',
                        new models.AddressPosition(data)

    class NavigationHeaderView extends SMLayout
        # This view is responsible for rendering the navigation
        # header which allows the user to switch between searching
        # and browsing.
        className: 'container'
        template: 'navigation-header'
        regions:
            search: '#search-region'
            browse: '#browse-region'
        events:
            'click .header': 'open'
            'click .action-button.close-button': 'close'
        initialize: (options) ->
            @navigation_layout = options.layout
            @search_state = options.search_state
            @search_results = options.search_results
            @selected_units = options.selected_units
            @listenTo @search_state, 'change:input_query', (model, value, opts) =>
                if opts.initial
                    @_open 'search'
                unless value or opts.clearing or opts.keep_open
                    @_close 'search'
        onShow: ->
            @search.show new SearchInputView(@search_state, @search_results)
            @browse.show new BrowseButtonView()
        _open: (action_type) ->
            @update_classes action_type
            @navigation_layout.open_view_type = action_type
            @navigation_layout.change action_type
        open: (event) ->
            @_open $(event.currentTarget).data('type')
        _close: (header_type) ->
            @update_classes null

            # Clear search query if search is closed.
            if header_type is 'search'
                @$el.find('input').val('')
                app.commands.execute 'closeSearch'
            if header_type is 'search' and not @selected_units.isEmpty()
                # Don't switch out of unit details when closing search.
                return
            @navigation_layout.close_contents()
        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            unless $(event.currentTarget).hasClass('close-button')
                return false
            header_type = $(event.target).closest('.header').data('type')
            @_close header_type
        update_classes: (opening) ->
            classname = "#{opening}-open"
            if @$el.hasClass classname
                return
            @$el.removeClass().addClass('container')
            if opening?
                @$el.addClass classname

    class NavigationLayout extends SMLayout
        className: 'service-sidebar'
        template: 'navigation-layout'
        regionType: SidebarRegion
        regions:
            header: '#navigation-header'
            contents: '#navigation-contents'
        onShow: ->
            @header.show new NavigationHeaderView
                layout: this
                search_state: @search_state
                search_results: @search_results
                selected_units: @selected_units
        initialize: (options) ->
            @service_tree_collection = options.service_tree_collection
            @selected_services = options.selected_services
            @search_results = options.search_results
            @selected_units = options.selected_units
            @selected_events = options.selected_events
            @selected_position = options.selected_position
            @search_state = options.search_state
            @routing_parameters = options.routing_parameters
            @user_click_coordinate_position = options.user_click_coordinate_position
            @breadcrumbs = [] # for service-tree view
            @open_view_type = null # initially the sidebar is closed.
            @add_listeners()
        add_listeners: ->
            @listenTo @search_results, 'reset', ->
                unless @search_results.isEmpty()
                    @change 'search'
            @listenTo @search_results, 'ready', ->
                unless @search_results.isEmpty()
                    @change 'search'
            @listenTo @service_tree_collection, 'sync', ->
                @change 'browse'
            @listenTo @selected_services, 'reset', ->
                @change 'browse'
            @listenTo @selected_position, 'change:value', ->
                if @selected_position.isSet()
                    @change 'position'
                else if @open_view_type = 'position'
                    @close_contents()
            @listenTo @selected_services, 'add', ->
                @close_contents()
            @listenTo @selected_units, 'reset', (unit, coll, opts) ->
                current_view_type = @contents.currentView?.type
                if current_view_type == 'details'
                    if @search_results.isEmpty() and @selected_units.isEmpty()
                        @close_contents()
                unless @selected_units.isEmpty()
                    @change 'details'
            @listenTo @selected_units, 'remove', (unit, coll, opts) ->
                @change null
            @listenTo @selected_events, 'reset', (unit, coll, opts) ->
                unless @selected_events.isEmpty()
                    @change 'event'
            $(window).resize =>
                @contents.currentView?.set_max_height?()
        right_edge_coordinate: ->
            if @opened
                @$el.offset().left + @$el.outerWidth()
            else
                0
        get_animation_type: (new_view_type) ->
            current_view_type = @contents.currentView?.type
            if current_view_type
                switch current_view_type
                    when 'event'
                        return 'right'
                    when 'details'
                        switch new_view_type
                            when 'event' then return 'left'
                            when 'details' then return 'up-and-down'
                            else return 'right'
                    when 'service-tree'
                        return @contents.currentView.animation_type or 'left'
            return null

        close_contents: ->
            @open_view_type = null
            @change null
            @header.currentView.update_classes null

        change: (type) ->
            if type is null
                type = @open_view_type

            # Only render service tree if browse is open in the sidebar.
            if type == 'browse' and @open_view_type != 'browse'
                return

            switch type
                when 'browse'
                    view = new ServiceTreeView
                        collection: @service_tree_collection
                        selected_services: @selected_services
                        breadcrumbs: @breadcrumbs
                when 'search'
                    view = new SearchLayoutView
                        collection: @search_results
                when 'details'
                    view = new DetailsView
                        model: @selected_units.first()
                        routing_parameters: @routing_parameters
                        search_results: @search_results
                        selected_units: @selected_units
                        user_click_coordinate_position: @user_click_coordinate_position
                when 'event'
                    view = new EventView
                        model: @selected_events.first()
                when 'position'
                    view = new PositionDetailsView
                        model: @selected_position.value()
                        selected_position: @selected_position
                else
                    @opened = false
                    view = null
                    @contents.close()

            # Update personalisation icon visibility.
            if type in ['browse', 'search', 'details', 'event']
                $('#personalisation').addClass('hidden')
            else
                $('#personalisation').removeClass('hidden')

            if view?
                @contents.show view, {animation_type: @get_animation_type(type)}
                @opened = true

    # class LegSummaryView extends SMItemView
    # TODO: use this instead of hardcoded template
    # in routingsummaryview
    #     template: 'routing-leg-summary'
    #     tagName: 'span'
    #     className: 'icon-icon-public-transport'

    # Todo: add a new layout analogous to the navigation layout
    # to centrally handle all the upper right hand side
    # customizations.
    #
    # class CustomizationLayout extends SMLayout

    class TransportModeControlsView extends SMItemView
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

    class RouteControllersView extends SMItemView
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

    class RouteSettingsHeaderView extends SMItemView
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

    class RouteSettingsView extends SMLayout
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

    class RoutingSummaryView extends SMItemView
        #itemView: LegSummaryView
        #itemViewContainer: '#route-details'
        template: 'routing-summary'
        className: 'route-summary'
        events:
            'click .route-selector a': 'switch_itinerary'
            'click .accessibility-viewpoint': 'set_accessibility'

        initialize: (options) ->
            @selected_itinerary_index = 0
            @itinery_choices_start_index = 0
            @user_click_coordinate_position = options.user_click_coordinate_position
            @details_open = false
            @skip_route = options.no_route
            @route = @model.get 'route'

        NUMBER_OF_CHOICES_SHOWN = 3

        LEG_MODES =
            WALK:
                icon: 'icon-icon-by-foot'
                color_class: 'transit-walk'
                text: i18n.t('transit.walk')
            BUS:
                icon: 'icon-icon-bus'
                color_class: 'transit-default'
                text: i18n.t('transit.bus')
            BICYCLE:
                icon: 'icon-icon-bicycle'
                color_class: 'transit-bicycle'
                text: i18n.t('transit.bicycle')
            CAR:
                icon: 'icon-icon-car'
                color_class: 'transit-car'
                text: i18n.t('transit.car')
            TRAM:
                icon: 'icon-icon-tram'
                color_class: 'transit-tram'
                text: i18n.t('transit.tram')
            SUBWAY:
                icon: 'icon-icon-subway'
                color_class: 'transit-subway'
                text: i18n.t('transit.subway')
            RAIL:
                icon: 'icon-icon-train'
                color_class: 'transit-rail',
                text: i18n.t('transit.rail')
            FERRY:
                icon: 'icon-icon-ferry'
                color_class: 'transit-ferry'
                text: i18n.t('transit.ferry')
            WAIT:
                icon: '',
                color_class: 'transit-default'
                text: i18n.t('transit.wait')

        MODES_WITH_STOPS = [
            'BUS'
            'FERRY'
            'RAIL'
            'SUBWAY'
            'TRAM'
        ]

        serializeData: ->
            if @skip_route
                return skip_route: true

            window.debug_route = @route

            itinerary = @route.plan.itineraries[@selected_itinerary_index]
            filtered_legs = _.filter(itinerary.legs, (leg) -> leg.mode != 'WAIT')

            mobility_accessibility_mode = p13n.get_accessibility_mode 'mobility'
            mobility_element = null
            if mobility_accessibility_mode
                mobility_element = p13n.get_profile_element mobility_accessibility_mode
            else
                mobility_element = LEG_MODES['WALK']

            legs = _.map(filtered_legs, (leg) =>
                steps = @parse_steps leg

                if leg.mode == 'WALK'
                    icon = mobility_element.icon
                    if mobility_accessibility_mode == 'wheelchair'
                        text = i18n.t 'transit.mobility_mode.wheelchair'
                    else
                        text = i18n.t 'transit.walk'
                else
                    icon = LEG_MODES[leg.mode].icon
                    text = LEG_MODES[leg.mode].text
                if leg.from.bogusName
                    start_location = i18n.t "otp.bogus_name.#{leg.from.name.replace ' ', '_' }"
                start_time: moment(leg.startTime).format('LT')
                start_location: start_location || p13n.get_translated_attr(leg.from.translatedName) || leg.from.name
                distance: @get_leg_distance leg, steps
                icon: icon
                transit_color_class: LEG_MODES[leg.mode].color_class
                transit_mode: text
                route: @get_route_text leg
                transit_destination: @get_transit_destination leg
                steps: steps
                has_warnings: !!_.find(steps, (step) -> step.warning)
            )

            end = {
                time: moment(itinerary.endTime).format('LT')
                name: p13n.get_translated_attr(@route.plan.to.translatedName) || @route.plan.to.name
                address: p13n.get_translated_attr(
                    @model.get_destination().get 'street_address'
                )
            }

            route = {
                duration: Math.round(itinerary.duration / 60) + ' min'
                walk_distance: (itinerary.walkDistance / 1000).toFixed(1) + 'km'
                legs: legs
                end: end
            }

            return {
                skip_route: false
                profile_set: _.keys(p13n.get_accessibility_profile_ids(true)).length
                itinerary: route
                itinerary_choices: @get_itinerary_choices()
                selected_itinerary_index: @selected_itinerary_index
                details_open: @details_open
                current_time: moment(new Date()).format('YYYY-MM-DDTHH:mm')
            }

        parse_steps: (leg) ->
            steps = []

            if leg.mode in ['WALK', 'BICYCLE', 'CAR']
                for step in leg.steps
                    warning = null
                    if step.bogusName
                        step.streetName = i18n.t "otp.bogus_name.#{step.streetName.replace ' ', '_' }"
                    else if p13n.get_translated_attr step.translatedName
                        step.streetName = p13n.get_translated_attr step.translatedName
                    text = i18n.t "otp.step_directions.#{step.relativeDirection}",
                        {street: step.streetName, postProcess: "fixFinnishStreetNames"}
                    if 'alerts' of step and step.alerts.length
                        warning = step.alerts[0].alertHeaderText.someTranslation
                    steps.push(text: text, warning: warning)
            else if leg.mode in MODES_WITH_STOPS and leg.intermediateStops
                if 'alerts' of leg and leg.alerts.length
                    for alert in leg.alerts
                        steps.push(
                            text: ""
                            warning: alert.alertHeaderText.someTranslation
                        )
                for stop in leg.intermediateStops
                    steps.push(
                        text: p13n.get_translated_attr(stop.translatedName) || stop.name
                        time: moment(stop.arrival).format('LT')
                    )
            else
                steps.push(text: 'No further info.')


            return steps

        get_leg_distance: (leg, steps) ->
            if leg.mode in MODES_WITH_STOPS
                return "#{steps.length} #{i18n.t('transit.stops')}"
            else
                return (leg.distance / 1000).toFixed(1) + 'km'

        get_transit_destination: (leg) ->
            if leg.mode in MODES_WITH_STOPS
                return "#{i18n.t('transit.toward')} #{leg.headsign}"
            else
                return ''

        get_route_text: (leg) ->
            route = if leg.route.length < 5 then leg.route else ''
            if leg.mode == 'FERRY'
                route = ''
            return route

        get_itinerary_choices: ->
            number_of_itineraries = @route.plan.itineraries.length
            start = @itinery_choices_start_index
            stop = Math.min(start + NUMBER_OF_CHOICES_SHOWN, number_of_itineraries)
            return _.range(start, stop)

        switch_itinerary: (event) ->
            event.preventDefault()
            @selected_itinerary_index = $(event.currentTarget).data('index')
            @details_open = true
            @route.draw_itinerary @selected_itinerary_index
            @render()

        set_accessibility: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'

    class EventListRowView extends SMItemView
        tagName: 'li'
        template: 'event-list-row'
        events:
            'click .show-event-details': 'show_event_details'

        serializeData: ->
            start_time = @model.get 'start_time'
            end_time = @model.get 'end_time'
            formatted_datetime = dateformat.humanize_event_datetime(
                start_time, end_time, 'small')
            name: p13n.get_translated_attr(@model.get 'name')
            datetime: formatted_datetime
            info_url: p13n.get_translated_attr(@model.get 'info_url')

        show_event_details: (event) ->
            event.preventDefault()
            app.commands.execute 'selectEvent', @model

    class EventListView extends SMCollectionView
        tagName: 'ul'
        className: 'events'
        itemView: EventListRowView
        initialize: (opts) ->
            @parent = opts.parent


    class EventView extends SMLayout
        id: 'event-view-container'
        className: 'navigation-element'
        template: 'event'
        events:
            'click .back-button': 'go_back'
            'click .sp-name a': 'go_back'
        type: 'event'

        initialize: (options) ->
            @embedded = options.embedded
            @service_point = @model.get('unit')

        serializeData: ->
            data = @model.toJSON()
            data.embedded_mode = @embedded
            start_time = @model.get 'start_time'
            end_time = @model.get 'end_time'
            data.datetime = dateformat.humanize_event_datetime(
                start_time, end_time, 'large')
            if @service_point?
                data.sp_name = @service_point.get 'name'
                data.sp_url = @service_point.get 'www_url'
                data.sp_phone = @service_point.get 'phone'
            else
                data.sp_name = @model.get('location_extra_info')
                data.prevent_back = true
            data

        go_back: (event) ->
            event.preventDefault()
            app.commands.execute 'clearSelectedEvent'
            app.commands.execute 'selectUnit', @service_point

        set_max_height: () ->
            # Set the event view content max height for proper scrolling.
            # Must be called after the view has been inserted to DOM.
            max_height = $(window).innerHeight() - @$el.find('.content').offset().top
            @$el.find('.content').css 'max-height': max_height

    class AccessibilityViewpointView extends SMItemView
        template: 'accessibility-viewpoint-summary'
        events: 'click .set-accessibility-profile': 'open_accessibility_menu'

        initialize: (opts) ->
            @filter_transit = opts?.filter_transit or false
            @template = @options.template or @template
        serializeData: ->
            profiles = p13n.get_accessibility_profile_ids @filter_transit
            return {
                profile_set: _.keys(profiles).length
                profiles: p13n.get_profile_elements profiles
            }
        open_accessibility_menu: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'

    class AccessibilityDetailsView extends SMLayout
        className: 'unit-accessibility-details'
        template: 'unit-accessibility-details'
        regions:
            'viewpoint_region': '.accessibility-viewpoint'
        events:
            'click #accessibility-collapser': 'toggle_collapse'
        toggle_collapse: ->
            @collapsed = !@collapsed
            true # important: bubble the event
        initialize: ->
            @listenTo p13n, 'change', @render
            @listenTo accessibility, 'change', @render
            @collapsed = true
            @accessibility_sentences = {}
            accessibility_sentences.fetch id: @model.id,
                (data) =>
                    @accessibility_sentences = data
                    @render()
        onRender: ->
            if @has_data
                @viewpoint_region.show new AccessibilityViewpointView()
        serializeData: ->
            @has_data = @model.get('accessibility_properties')?.length
            profiles = p13n.get_accessibility_profile_ids()
            details = []
            sentence_groups = []
            header_classes = []
            short_text = ''

            profile_set = true
            if not _.keys(profiles).length
                profile_set = false
                profiles = p13n.get_all_accessibility_profile_ids()

            seen = {}
            shortcomings_pending = false
            shortcomings_count = 0
            if @has_data
                shortcomings = {}
                for pid in _.keys profiles
                    shortcoming = accessibility.get_shortcomings(@model.get('accessibility_properties'), pid)
                    if shortcoming.status != 'complete'
                        shortcomings_pending = true
                        break
                    if _.keys(shortcoming.messages).length
                        for segment_id, segment_messages of shortcoming.messages
                            shortcomings[segment_id] = shortcomings[segment_id] or {}
                            for requirement_id, messages of segment_messages
                                gathered_messages = []
                                for msg in messages
                                    translated = p13n.get_translated_attr msg
                                    if translated not of seen
                                        seen[translated] = true
                                        gathered_messages.push msg
                                if gathered_messages.length
                                    shortcomings[segment_id][requirement_id] = gathered_messages

                if 'error' of @accessibility_sentences
                    details = null
                    sentence_groups = null
                    sentence_error = true
                else
                    details = _.object _.map(
                        @accessibility_sentences.sentences,
                        (sentences, group_id) =>
                            [p13n.get_translated_attr(@accessibility_sentences.groups[group_id]),
                             _.map(sentences, (sentence) -> p13n.get_translated_attr sentence)])

                    sentence_groups = _.map _.values(@accessibility_sentences.groups), (v) -> p13n.get_translated_attr(v)
                    sentence_error = false

            for __, group of shortcomings
                shortcomings_count += _.values(group).length
            collapse_classes = []
            if @collapsed
                header_classes.push 'collapsed'
            else
                collapse_classes.push 'in'

            if @has_data and _.keys(profiles).length
                if shortcomings_count
                    if profile_set
                        header_classes.push 'has-shortcomings'
                        short_text = i18n.t('accessibility.shortcoming_count', {count: shortcomings_count})
                else
                    if shortcomings_pending
                        header_classes.push 'shortcomings-pending'
                        short_text = i18n.t('accessibility.pending')
                    else if profile_set
                        header_classes.push 'no-shortcomings'
                        short_text = i18n.t('accessibility.no_shortcomings')
            else if _.keys(profiles).length
                short_text = i18n.t('accessibility.no_data')

            profile_set: profile_set
            icon_class:
                if profile_set
                    p13n.get_profile_elements(profiles).pop()['icon']
                else
                    'icon-icon-wheelchair'
            shortcomings_pending: shortcomings_pending
            shortcomings_count: shortcomings_count
            shortcomings: shortcomings
            groups: sentence_groups
            details: details
            sentence_error: sentence_error
            feedback: @get_dummy_feedback()
            header_classes: header_classes.join ' '
            collapse_classes: collapse_classes.join ' '
            short_text: short_text
            has_data: @has_data

        get_dummy_feedback: ->
            now = new Date()
            yesterday = new Date(now.setDate(now.getDate() - 1))
            last_month = new Date(now.setMonth(now.getMonth() - 1))
            feedback = []
            feedback.push(
                time: moment(yesterday).calendar()
                profile: 'wheelchair user.'
                header: 'The ramp is too steep'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )
            feedback.push(
                time: moment(last_month).calendar()
                profile: 'rollator user'
                header: 'Not accessible at all and the staff are unhelpful!!!!'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )

            feedback

        leave_feedback_on_accessibility: (event) ->
            event.preventDefault()
            # TODO: Add here functionality for leaving feedback.

    class PositionDetailsView extends SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'position'
        regions: 'admin_divisions': '.admin-div-placeholder'
        events:
            'click .icon-icon-close': 'self_destruct'
        initialize: (opts) ->
            @model = opts.model
            @selected_position = opts.selected_position
            @div_list = new models.AdministrativeDivisionList()
            @listenTo @model, 'reverse_geocode', =>
                @fetch_divisions().done =>
                    @render()
            correct_order = [
                'neighborhood',
                'rescue_district',
                'health_station_district',
                'income_support_district']
            @div_list.comparator = (a, b) =>
                index_a = _.indexOf correct_order, a.get('type')
                index_b = _.indexOf correct_order, b.get('type')
                if index_a < index_b then return -1
                if index_b < index_a then return 1
                return 0
            @listenTo @div_list, 'reset', @render_admin_divs
            @fetch_divisions()
        fetch_divisions: ->
            coords = @model.get('location').coordinates
            @div_list.fetch
                data:
                    lon: coords[0]
                    lat: coords[1]
                    unit_include: 'name,root_services,location'
                    type: 'neighborhood,income_support_district,health_station_district,rescue_district'
                    geometry: 'false'
                reset: true
        serializeData: ->
            data = super()
            data.icon_class = switch @model.origin()
                when 'address' then 'icon-icon-address'
                when 'detected' then 'icon-icon-you-are-here'
                when 'clicked' then 'icon-icon-address'
            data.origin = @model.origin()
            data
        onRender: ->
            @render_admin_divs()
            @set_max_height()
        set_max_height: =>
            max_height = $(window).innerHeight() - $('#navigation-contents').offset().top
            @$el.css 'max-height': max_height
        render_admin_divs: ->
            @admin_divisions.show new DivisionListView
                collection: @div_list

        self_destruct: ->
            @selected_position.clear()

    class DetailsView extends SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'details'
        regions:
            'route_settings_region': '.route-settings'
            'route_summary_region': '.route-summary'
            'accessibility_region': '.section.accessibility-section'
            'events_region': '.event-list'
        events:
            'click .back-button': 'user_close'
            'click .icon-icon-close': 'user_close'
            'click .map-active-area': 'show_map'
            'click .show-map': 'show_map'
            'click .mobile-header': 'show_content'
            'click .show-more-events': 'show_more_events'
            'click .disabled': 'prevent_disabled_click'
            'click .leave-feedback': 'leave_feedback_on_accessibility'
            'click .section.route-section a.collapser.route': 'toggle_route'
            'click .section.main-info .description .body-expander': 'toggle_description_body'
        type: 'details'

        initialize: (options) ->
            @INITIAL_NUMBER_OF_EVENTS = 5
            @NUMBER_OF_EVENTS_FETCHED = 20
            @embedded = options.embedded
            @search_results = options.search_results
            @selected_units = options.selected_units
            @user_click_coordinate_position = options.user_click_coordinate_position
            @routing_parameters = options.routing_parameters
            @listenTo p13n, 'change', @change_transit_icon
            @listenTo @routing_parameters, 'complete', @request_route
            @listenTo @search_results, 'reset', @render

        render: ->
            super()
            marker_canvas = @$el.find('#details-marker-canvas').get(0)
            marker_canvas_mobile = @$el.find('#details-marker-canvas-mobile').get(0)
            context = marker_canvas.getContext('2d')
            context_mobile = marker_canvas_mobile.getContext('2d')
            size = 40
            color = app.color_matcher.unit_color(@model) or 'rgb(0, 0, 0)'
            id = 0
            rotation = 90

            marker = new draw.Plant size, color, id, rotation
            marker.draw context
            marker.draw context_mobile

        get_transit_icon: () ->
            set_modes = _.filter (_.pairs p13n.get('transport')), ([k, v]) -> v == true
            mode = set_modes.pop()[0]
            mode_icon_name = mode.replace '_', '-'
            "icon-icon-#{mode_icon_name}"

        change_transit_icon: ->
            $icon_el = @$el.find('.section.route-section #route-section-icon')
            $icon_el.removeClass().addClass @get_transit_icon()

        onRender: ->
            # Events
            #
            if @model.event_list.isEmpty()
                @listenTo @model.event_list, 'reset', (list) =>
                    @update_events_ui(list.fetchState)
                    @render_events(list)
                @model.event_list.pageSize = @INITIAL_NUMBER_OF_EVENTS
                @model.get_events()
                @model.event_list.pageSize = @NUMBER_OF_EVENTS_FETCHED
            else
                @update_events_ui(@model.event_list.fetchState)
                @render_events(@model.event_list)

            @accessibility_region.show new AccessibilityDetailsView
                model: @model


        update_events_ui: (fetchState) =>
            $events_section = @$el.find('.events-section')

            # Update events section short text count.
            if fetchState.count
                short_text = i18n.t 'sidebar.event_count',
                    count: fetchState.count
            else
                # Handle no events -cases.
                short_text = i18n.t('sidebar.no_events')
                @$('.show-more-events').hide()
                $events_section.find('.collapser').addClass('disabled')
            $events_section.find('.short-text').text(short_text)

            # Remove show more button if all events are visible.
            if !fetchState.next and @model.event_list.length == @events_region.currentView?.collection.length
                @$('.show-more-events').hide()

        user_close: (event) ->
            app.commands.execute 'clearSelectedUnit'
            unless @search_results.isEmpty()
                app.commands.execute 'search'

        prevent_disabled_click: (event) ->
            event.preventDefault()
            event.stopPropagation()

        show_map: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'

        show_content: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'

        set_max_height: () ->
            # Set the details view content max height for proper scrolling.
            # Must be called after the view has been inserted to DOM.
            max_height = $(window).innerHeight() - @$el.find('.content').offset().top
            @$el.find('.content').css 'max-height': max_height

        get_translated_provider: (provider_type) ->
            SUPPORTED_PROVIDER_TYPES = [101, 102, 103, 104, 105]
            if provider_type in SUPPORTED_PROVIDER_TYPES
                i18n.t("sidebar.provider_type.#{ provider_type }")
            else
                ''

        serializeData: ->
            embedded = @embedded
            data = @model.toJSON()
            data.provider = @get_translated_provider @model.get 'provider_type'
            unless @search_results.isEmpty()
                data.back_to = i18n.t 'sidebar.back_to.search'
            MAX_LENGTH = 20
            description = data.description
            if description
                words = description.split /[ ]+/
                if words.length > MAX_LENGTH + 1
                    data.description_ingress = words[0...MAX_LENGTH].join ' '
                    data.description_body = words[MAX_LENGTH...].join ' '
                else
                    data.description_ingress = description

            data.embedded_mode = embedded
            data.transit_icon = @get_transit_icon()
            data


        render_events: (events) ->
            if events?
                @events_region.show new EventListView
                    collection: events

        show_more_events: (event) ->
            event.preventDefault()
            options =
                spinner_options:
                    container: @$('.show-more-events').get(0)
                    hide_container_content: true
            if @model.event_list.length <= @INITIAL_NUMBER_OF_EVENTS
                @model.get_events({}, options)
            else
                options.success = =>
                    @update_events_ui(@model.event_list.fetchState)
                @model.event_list.fetchNext(options)

        toggle_description_body: (ev) ->
            $target = $(ev.currentTarget)
            $target.toggle()
            $target.closest('.description').find('.body').toggle()

        toggle_route: (ev) ->
            $element = $(ev.currentTarget)
            if $element.hasClass 'collapsed'
                @show_route()
            else
                @hide_route()

        show_route: ->
            # Route planning
            #
            last_pos = p13n.get_last_position()
            # Ensure that any user entered position is the origin for the new route
            # so that setting the destination won't overwrite the user entered data.
            @routing_parameters.ensure_unit_destination()
            @routing_parameters.set_destination @model
            previous_origin = @routing_parameters.get_origin()
            if last_pos
                if not previous_origin
                    @routing_parameters.set_origin last_pos,
                        silent: true
                @request_route()
            else
                @listenTo p13n, 'position', (pos) =>
                    @request_route()
                @listenTo p13n, 'position_error', =>
                    @show_route_summary null
                if not previous_origin
                    @routing_parameters.set_origin new models.CoordinatePosition
                p13n.request_location @routing_parameters.get_origin()

            @route_settings_region.show new RouteSettingsView
                model: @routing_parameters
                unit: @model
                user_click_coordinate_position: @user_click_coordinate_position

            @show_route_summary null

        show_route_summary: (route) ->
            @route_summary_region.show new RoutingSummaryView
                model: @routing_parameters
                user_click_coordinate_position: @user_click_coordinate_position
                no_route: !route?

        request_route: ->
            if @route?
                @route.clear_itinerary()
            if not @routing_parameters.is_complete()
                return

            spinner = new SMSpinner
                container:
                    @$el.find('#route-details .route-spinner').get(0)
            spinner.start()

            if not @route?
                @route = new transit.Route window.map_view.map, @selected_units
                @listenTo @route, 'plan', (plan) =>
                    @routing_parameters.set 'route', @route
                    @route.draw_itinerary()
                    @show_route_summary @route
                    spinner.stop()
                @listenTo @route, 'error', =>
                    spinner.stop()
                @listenTo p13n, 'change', (path, val) =>
                    # if path[0] == 'accessibility'
                    #     if path[1] != 'mobility'
                    #         return
                    # else if path[0] != 'transport'
                    #     return
                    @request_route()

            @routing_parameters.unset 'route'

            # railway station '60.171944,24.941389'
            # satamatalo 'osm:node:347379939'
            opts = {}
            #if p13n.get_accessibility_mode('mobility') in [
            #    'wheelchair', 'stroller', 'reduced_mobility'
            #]
            #    opts.wheelchair = true

            if p13n.get_accessibility_mode('mobility') == 'wheelchair'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkBoardCost = 12*60
                opts.walkSpeed = 0.75
                opts.minTransferTime = 3*60+1

            if p13n.get_accessibility_mode('mobility') == 'reduced_mobility'
                opts.walkReluctance = 5
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 0.5

            if p13n.get_accessibility_mode('mobility') == 'rollator'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkSpeed = 0.5
                opts.walkBoardCost = 12*60

            if p13n.get_accessibility_mode('mobility') == 'stroller'
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 1

            if p13n.get_transport 'bicycle'
                opts.bicycle = true
            if p13n.get_transport 'car'
                opts.car = true
            if p13n.get_transport 'public_transport'
                opts.transit = true

            datetime = @routing_parameters.get_datetime()
            opts.date = moment(datetime).format('YYYY/MM/DD')
            opts.time = moment(datetime).format('HH:mm')
            opts.arriveBy = @routing_parameters.get('time_mode') == 'arrive'

            from = @routing_parameters.get_origin().otp_serialize_location
                force_coordinates: opts.car
            to = @routing_parameters.get_destination().otp_serialize_location
                force_coordinates: opts.car

            @route.request_plan from, to, opts

        hide_route: ->
            if @route?
                @route.clear_itinerary window.debug_map

    class ServiceTreeView extends SMLayout
        id: 'service-tree-container'
        className: 'navigation-element'
        template: 'service-tree'
        events:
            'click .service.has-children': 'open_service'
            'click .service.parent': 'open_service'
            'click .crumb': 'handle_breadcrumb_click'
            'click .service.leaf': 'toggle_leaf'
            'click .service .show-icon': 'toggle_button'
            'mouseenter .service .show-icon': 'show_tooltip'
            'mouseleave .service .show-icon': 'remove_tooltip'
        type: 'service-tree'

        initialize: (options) ->
            @selected_services = options.selected_services
            @breadcrumbs = options.breadcrumbs
            @animation_type = 'left'
            @scrollPosition = 0
            @listenTo @selected_services, 'remove', @render
            @listenTo @selected_services, 'add', @render
            @listenTo @selected_services, 'reset', @render

        toggle_leaf: (event) ->
            @toggle_element($(event.currentTarget).find('.show-icon'))

        toggle_button: (event) ->
            @remove_tooltip()
            event.preventDefault()
            event.stopPropagation()
            @toggle_element($(event.target))

        show_tooltip: (event) ->
            @remove_tooltip()
            @$tooltip_element = $("<div id=\"tooltip\">#{i18n.t('sidebar.show_tooltip')}</div>")
            $target_el = $(event.currentTarget)
            $('body').append @$tooltip_element
            button_offset = $target_el.offset()
            original_offset = @$tooltip_element.offset()
            @$tooltip_element.css 'top', "#{button_offset.top + original_offset.top}px"
            @$tooltip_element.css 'left', "#{button_offset.left + original_offset.left}px"
        remove_tooltip: (event) ->
            @$tooltip_element?.remove()

        get_show_icon_classes: (showing, root_id) ->
            if showing
                return "show-icon selected service-color-#{root_id}"
            else
                return "show-icon service-hover-color-#{root_id}"

        toggle_element: ($target_element) ->
            service_id = $target_element.closest('li').data('service-id')
            unless @selected(service_id) is true
                app.commands.execute 'clearSearchResults'
                service = new models.Service id: service_id
                service.fetch
                    success: =>
                        app.commands.execute 'addService', service
            else
                app.commands.execute 'removeService', service_id

        handle_breadcrumb_click: (event) ->
            event.preventDefault()
            # We need to stop the event from bubling to the containing element.
            # That would make the service tree go back only one step even if
            # user is clicking an earlier point in breadcrumbs.
            event.stopPropagation()
            @open_service(event)

        open_service: (event) ->
            $target = $(event.currentTarget)
            service_id = $target.data('service-id')
            service_name = $target.data('service-name')
            @animation_type = $target.data('slide-direction')

            if not service_id
                return null

            if service_id == 'root'
                service_id = null
                # Use splice to affect the original breadcrumbs array.
                @breadcrumbs.splice 0, @breadcrumbs.length
            else
                # See if the service is already in the breadcrumbs.
                index = _.indexOf(_.pluck(@breadcrumbs, 'service_id'), service_id)
                if index != -1
                    # Use splice to affect the original breadcrumbs array.
                    @breadcrumbs.splice index, @breadcrumbs.length - index
                @breadcrumbs.push(service_id: service_id, service_name: service_name)

            spinner_options =
                container: $target.get(0)
                hide_container_content: true
            @collection.expand service_id, spinner_options

        onRender: ->
            if @service_to_display
                $target_element = @$el.find("[data-service-id=#{@service_to_display.id}]").find('.show-icon')
                @service_to_display = false
                @toggle_element($target_element)

            $ul = @$el.find('ul')
            $ul.on('scroll', (ev) =>
                @scrollPosition = ev.currentTarget.scrollTop)
            $ul.scrollTop(@scrollPosition)
            @scrollPosition = 0

            @set_max_height()
            @set_breadcrumb_widths()

        set_max_height: (height) =>
            if height?
                max_height = height
            else
                max_height = $(window).innerHeight() - @$el.offset().top
            @$el.find('.service-tree').css 'max-height': max_height

        set_breadcrumb_widths: ->
            CRUMB_MIN_WIDTH = 40
            # We need to use the last() jQuery method here, because at this
            # point the animations are still running and the DOM contains,
            # both the old and the new content. We only want to get the new
            # content and its breadcrumbs as a basis for our calculations.
            $container = @$el.find('.header-item').last()
            $crumbs = $container.find('.crumb')
            return unless $crumbs.length > 1

            # The last breadcrumb is given preference, so separate that from the
            # rest of the breadcrumbs.
            $last_crumb = $crumbs.last()
            $crumbs = $crumbs.not(':last')

            $chevrons = $container.find('.icon-icon-forward')
            space_available = $container.width() - ($chevrons.length * $chevrons.first().outerWidth())
            last_width = $last_crumb.width()
            space_needed = last_width + $crumbs.length * CRUMB_MIN_WIDTH

            if space_needed > space_available
                # Not enough space -> make the last breadcrumb narrower.
                last_width = space_available - $crumbs.length * CRUMB_MIN_WIDTH
                $last_crumb.css('max-width': last_width)
                $crumbs.css('max-width': CRUMB_MIN_WIDTH)
            else
                # More space -> Make the other breadcrumbs wider.
                crumb_width = (space_available - last_width) / $crumbs.length
                $crumbs.css('max-width': crumb_width)

        selected: (service_id) ->
            @selected_services.get(service_id)?
        close: ->
            @remove_tooltip()
            @remove()
            @stopListening()

        serializeData: ->
            classes = (category) ->
                if category.get('children').length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                selected = @selected(category.id)

                root_id = category.get 'root'

                id: category.get 'id'
                name: category.get_text 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: selected
                root_id: root_id
                show_icon_classes: @get_show_icon_classes selected, root_id

            parent_item = {}
            back = null

            if @collection.chosen_service
                back = @collection.chosen_service.get('parent') or 'root'
                parent_item.name = @collection.chosen_service.get_text 'name'
                parent_item.root_id = @collection.chosen_service.get 'root'

            data =
                back: back
                parent_item: parent_item
                list_items: list_items
                breadcrumbs: _.initial @breadcrumbs # everything but the last crumb

    class SearchResultView extends SMItemView
        tagName: 'li'
        events:
            'click': 'select_result'
            'mouseenter': 'highlight_result'
        template: 'search-result'

        select_result: (ev) ->
            if @model.get('object_type') == 'unit'
                app.commands.execute 'selectUnit', @model
            else if @model.get('object_type') == 'service'
                app.commands.execute 'addService', @model

        highlight_result: (ev) ->
            app.commands.execute 'highlightUnit', @model

        serializeData: ->
            data = super()
            data.specifier_text = @model.get_specifier_text()
            data

    class SearchResultsView extends SMCollectionView
        itemView: SearchResultView

    class DivisionListItemView extends SMItemView
        events:
            'click': 'handle_click'
        tagName: 'li'
        template: 'division-list-item'
        handle_click: =>
            if @model.has 'unit'
                unit = new models.Unit(@model.get('unit'))
                app.commands.execute 'setUnit', unit
                app.commands.execute 'selectUnit', unit
    class DivisionListView extends SMCollectionView
        tagName: 'ul'
        className: 'division-list'
        itemView: DivisionListItemView

    class SearchLayoutView extends SMLayout
        className: 'search-results navigation-element'
        template: 'search-results'
        events:
            'click .show-all': 'show_all'
        type: 'search'

        initialize: ->
            @category_collection = new models.SearchList()
            @service_point_collection = new models.SearchList()
            @listenTo @collection, 'add', _.debounce(@update_results, 10)
            @listenTo @collection, 'remove', _.debounce(@update_results, 10)
            @listenTo @collection, 'reset', @update_results
            @listenTo @collection, 'ready', @update_results
            @listenTo @collection, 'hide', => @$el.hide()

        show_all: (ev) ->
            ev?.preventDefault()
            console.log 'show all!'
            # TODO: Add functionality for querying and showing all results here.

        update_results: ->
            @$el.show()
            @category_collection.set @collection.where(object_type: 'service')
            @service_point_collection.set @collection.where(object_type: 'unit')
            @$('.categories, .categories + .show-all').addClass('hidden')
            @$('.service-points, .service-points + .show-all').addClass('hidden')

            if @category_collection.length
                header_text = i18n.t('sidebar.search_category_count', {count: @category_collection.length})
                show_all_text = i18n.t('sidebar.search_category_show_all', {count: @category_collection.length})
                @$('.categories, .categories + .show-all').removeClass('hidden')
                @$('.categories .header-item').text(header_text)
                @$('.categories + .show-all').text(show_all_text)

            if @service_point_collection.length
                header_text = i18n.t('sidebar.search_service_point_count', {count: @service_point_collection.length})
                show_all_text = i18n.t('sidebar.search_service_point_show_all', {count: @service_point_collection.length})
                @$('.service-points, .service-points + .show-all').removeClass('hidden')
                @$('.service-points .header-item').text(header_text)
                @$('.service-points + .show-all').text(show_all_text)

        onRender: ->
            @set_max_height()
            @category_results = new SearchResultsView
                collection: @category_collection
                el: @$('.categories')
            @service_point_results = new SearchResultsView
                collection: @service_point_collection
                el: @$('.service-points')
            if @collection.length
                @update_results()

        set_max_height: () =>
            max_height = $(window).innerHeight() - $('#navigation-contents').offset().top
            @$el.css 'max-height': max_height

    class ServiceCart extends SMItemView
        template: 'service-cart'
        tagName: 'ul'
        className: 'expanded container'
        events:
            'click .personalisation-container .maximizer': 'maximize'
            'click .button.cart-close-button': 'minimize'
            'click .button.close-button': 'close_service'
            'click a.layer-option': 'switch_map'
        initialize: (opts) ->
            @collection = opts.collection
            @listenTo @collection, 'add', @maximize
            @listenTo @collection, 'remove', =>
                if @collection.length
                    @render()
                else
                    @minimize()
            @listenTo @collection, 'reset', @render
            @listenTo @collection, 'minmax', @render
            if @collection.length
                @minimized = false
            else
                @minimized = true
        maximize: ->
            @minimized = false
            @collection.trigger 'minmax'
        minimize: ->
            @minimized = true
            @collection.trigger 'minmax'
        onRender: ->
            if @minimized
                @$el.removeClass 'expanded'
                @$el.addClass 'minimized'
            else
                @$el.addClass 'expanded'
                @$el.removeClass 'minimized'
        serializeData: ->
            if @minimized
                return minimized: true
            data = super()
            current_key = p13n.get 'map_background_layer'
            other_key = @other_layer()
            data.current_layer = i18n.t("service_cart.#{current_key}")
            data.layer_message = i18n.t("service_cart.change_to_#{other_key}")
            data
        close_service: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        other_layer: ->
            layer = _.find ['servicemap', 'guidemap'],
                (l) => l != p13n.get('map_background_layer')
        switch_map: (ev) ->
            p13n.set_map_background_layer @other_layer()


    class LanguageSelectorView extends SMItemView
        template: 'language-selector'
        events:
            'click .language': 'select_language'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.get_supported_languages()
            @refresh_collection()
        select_language: (ev) ->
            l = $(ev.currentTarget).data('language')
            @p13n.set_language(l)
            window.location.reload()
        refresh_collection: ->
            selected = @p13n.get_language()
            language_models = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter language_models, (l) -> !l.get('selected')

    class PersonalisationView extends SMItemView
        className: 'personalisation-container'
        template: 'personalisation'
        events:
            'click .personalisation-button': 'personalisation_button_click'
            'click .ok-button': 'toggle_menu'
            'click .select-on-map': 'select_on_map'
            'click .personalisations a': 'switch_personalisation'
            'click .personalisation-message a': 'open_menu_from_message'
            'click .personalisation-message .close-button': 'close_message'

        personalisation_icons:
            'city': [
                'helsinki'
                'espoo'
                'vantaa'
                'kauniainen'
            ]
            'senses': [
                'hearing_aid'
                'visually_impaired'
                'colour_blind'
            ]
            'mobility': [
                'wheelchair'
                'reduced_mobility'
                'rollator'
                'stroller'
            ]

        initialize: ->
            $(window).resize @set_max_height
            @listenTo p13n, 'change', ->
                @set_activations()
                @render_icons_for_selected_modes()
            @listenTo p13n, 'user:open', -> @personalisation_button_click()

        personalisation_button_click: (ev) ->
            ev?.preventDefault()
            unless $('#personalisation').hasClass('open')
                @toggle_menu(ev)

        toggle_menu: (ev) ->
            ev?.preventDefault()
            $('#personalisation').toggleClass('open')

        open_menu_from_message: (ev) ->
            ev?.preventDefault()
            @toggle_menu()
            @close_message()

        close_message: (ev) ->
            @$('.personalisation-message').removeClass('open')

        select_on_map: (ev) ->
            # Add here functionality for seleecting user's location from the map.
            ev.preventDefault()

        render_icons_for_selected_modes: ->
            $container = @$('.selected-personalisations').empty()
            for group, types of @personalisation_icons
                for type in types
                    if @mode_is_activated(type, group)
                        if group == 'city'
                            icon_class = 'icon-icon-coat-of-arms-' + type.split('_').join('-')
                        else
                            icon_class = 'icon-icon-' + type.split('_').join('-')
                        $icon = $("<span class='#{icon_class}'></span>")
                        $container.append($icon)

        mode_is_activated: (type, group) ->
            activated = false
            # FIXME
            if group == 'city'
                activated = p13n.get('city') == type
            else if group == 'mobility'
                activated = p13n.get_accessibility_mode('mobility') == type
            else
                activated = p13n.get_accessibility_mode type
            return activated

        set_activations: ->
            $list = @$el.find '.personalisations'
            $list.find('li').each (idx, li) =>
                $li = $(li)
                type = $li.data 'type'
                group = $li.data 'group'
                if @mode_is_activated(type, group)
                    $li.addClass 'selected'
                else
                    $li.removeClass 'selected'

        switch_personalisation: (ev) ->
            ev.preventDefault()
            parent_li = $(ev.target).closest 'li'
            group = parent_li.data 'group'
            type = parent_li.data 'type'

            if group == 'mobility'
                p13n.toggle_mobility type
            else if group == 'senses'
                p13n.toggle_accessibility_mode type
            else if group == 'city'
                p13n.toggle_city type

        render: (opts) ->
            super opts
            @render_icons_for_selected_modes()
            @set_activations()

        onRender: ->
            @set_max_height()

        set_max_height: =>
            # TODO: Refactor this when we get some onDomAppend event.
            # The onRender function that calls set_max_height runs before @el
            # is inserted into DOM. Hence calculating heights and positions of
            # the template elements is currently impossible.
            personalisation_header_height = 56
            window_width = $(window).width()
            offset = 0
            if window_width >= MOBILE_UI_BREAKPOINT
                offset = $('#personalisation').offset().top
            max_height = $(window).innerHeight() - personalisation_header_height - offset
            @$el.find('.personalisation-content').css 'max-height': max_height

    exports =
        LandingTitleView: LandingTitleView
        TitleView: TitleView
        ServiceTreeView: ServiceTreeView
        ServiceCart: ServiceCart
        LanguageSelectorView: LanguageSelectorView
        NavigationLayout: NavigationLayout
        PersonalisationView: PersonalisationView

    return exports
