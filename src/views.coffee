define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'moment', 'bootstrap-datetimepicker', 'typeahead.bundle', 'app/p13n', 'app/widgets', 'app/jade', 'app/models', 'app/search', 'app/color', 'app/draw', 'app/transit', 'app/animations', 'app/accessibility', 'app/sidebar-region', 'app/spinner'], (_, Backbone, Marionette, Leaflet, i18n, moment, datetimepicker, typeahead, p13n, widgets, jade, models, search, colors, draw, transit, animations, accessibility, SidebarRegion, SMSpinner) ->

    PAGE_SIZE = 200

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
        adapt_to_query: (model, opts) ->
            $container = @$el.find('.action-button')
            $icon = $container.find('span')
            if @$search_el.val().length == 0 and not @is_empty()
                @$search_el.val @model.get('input_query')
            if @is_empty()
                if @search_results.query
                    if opts? and opts.initial
                        @model.set 'input_query', @search_results.query
                        @render()
                else
                    @$search_el.val ''

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
        enable_typeahead: (selector) ->
            @$search_el = @$el.find selector
            service_dataset =
                source: search.servicemap_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
                    header: (ctx) -> jade.template 'typeahead-fulltext', ctx
            event_dataset =
                source: search.linkedevents_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    empty: ''
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx

            @$search_el.typeahead null, [service_dataset, event_dataset]

            # On enter: was there a selection from the autosuggestions
            # or did the user hit enter without having selected a
            # suggestion?
            selected = false
            @$search_el.on 'typeahead:selected', (ev) =>
                selected = true
            @$search_el.on 'input', (ev) =>
                @model.set 'input_query', @get_query()
                app.commands.execute 'clearSearchResults'
            @$search_el.keyup (ev) =>
                # Handle enter
                if ev.keyCode != 13
                    return
                if selected
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
            @listenTo @search_state, 'change', (model, opts) =>
                if opts.initial
                    @_open('search')
        onShow: ->
            @search.show new SearchInputView(@search_state, @search_results)
            @browse.show new BrowseButtonView()
        _open: (action_type) ->
            @update_classes action_type
            if action_type is 'search'
                @$el.find('input').select()
            @navigation_layout.open_view_type = action_type
            @navigation_layout.change action_type
        open: (event) ->
            @_open $(event.currentTarget).data('type')
        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            unless $(event.currentTarget).hasClass('close-button')
                return false
            header_type = $(event.target).closest('.header').data('type')
            @update_classes null

            # Clear search query if search is closed.
            if header_type is 'search'
                @$el.find('input').val('')
                app.commands.execute 'clearSearchResults'
                app.commands.execute 'closeSearch'
            else
                @navigation_layout.close_contents()
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
        initialize: (options) ->
            @service_tree_collection = options.service_tree_collection
            @selected_services = options.selected_services
            @search_results = options.search_results
            @selected_units = options.selected_units
            @selected_events = options.selected_events
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
            @listenTo @service_tree_collection, 'sync', ->
                @change 'browse'
            @listenTo @selected_services, 'reset', ->
                @change 'browse'
            @listenTo @selected_services, 'add', ->
                @close_contents()
            @listenTo @selected_units, 'reset', (unit, coll, opts) ->
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
                    view = new SearchResultsView
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
                else
                    @opened = false
                    view = null
                    @contents.close()

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

    class RoutingControlsView extends SMItemView
        template: 'routing-controls'
        className: 'route-controllers'
        events:
            'click .preset.unlocked': 'switch_to_location_input'
            'click .preset-current-time': 'switch_to_time_input'
            'click .preset-current-date': 'switch_to_date_input'
            'click .time-mode': 'switch_time_mode'
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
            @de_emphasized = true
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
            if @de_emphasized
                @$el.addClass 'de-emphasized'
                @de_emphasized = false
            else
                @$el.removeClass 'de-emphasized'
            @enable_typeahead '.row.transit-end input'
            @enable_typeahead '.row.transit-start input'
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
                address_position = new models.AddressPosition
                    address: match.name
                    coordinates: match.location.coordinates

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

        _location_name_and_class: (object) ->
            if not object?
                name: ''
                icon: null
            else if object.is_detected_location()
                if object.is_pending()
                    name: i18n.t('transit.location_pending')
                    icon: "fa fa-spinner fa-spin"
                else
                    name: i18n.t('transit.current_location')
                    icon: 'icon-icon-you-are-here'
            else if object instanceof models.CoordinatePosition
                name: i18n.t('transit.user_picked_location')
                icon: 'icon-icon-you-are-here'
            else if object instanceof models.Unit
                name: object.get_text('name')
                icon: "color-ball service-background-color-" + @current_unit.get('root_services')[0]
                lock: true
            else if object instanceof models.AddressPosition
                name: object.get('address')
                icon: null

        serializeData: ->
            datetime = moment @model.get_datetime()
            today = new Date()
            tomorrow = moment(today).add 1, 'days'
            is_today: not @force_date_input and datetime.isSame(today, 'day')
            is_tomorrow: datetime.isSame tomorrow, 'day'
            params: @model
            origin: @_location_name_and_class @model.get_origin()
            destination: @_location_name_and_class @model.get_destination()
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
            @user_click_coordinate_position.set 'value', position
            switch $(ev.currentTarget).attr 'data-route-node'
                when 'start' then @model.set_origin position
                when 'end' then @model.set_destination position
            @listenTo position, 'change', =>
                @apply_changes()
                @render()
            position.trigger 'request'

        switch_time_mode: (ev) ->
            ev.stopPropagation()
            @model.switch_time_mode()
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

    class RoutingSummaryView extends SMLayout
        #itemView: LegSummaryView
        #itemViewContainer: '#route-details'
        template: 'routing-summary'
        className: 'route-summary'
        events:
            'click .route-selector a': 'switch_itinerary'
            'click .switch-end-points': 'switch_end_points'
            'click .accessibility-viewpoint': 'set_accessibility'
        regions:
            'accessibility_summary_region': '.accessibility-viewpoint-part'

        initialize: (options) ->
            @selected_itinerary_index = 0
            @itinery_choices_start_index = 0
            @user_click_coordinate_position = options.user_click_coordinate_position
            @details_open = false
            @skip_route = options.no_route
            @route = @model.get 'route'

        onRender: ->
            @accessibility_summary_region.show new AccessibilityViewpointView
                filter_transit: true

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

        STEP_DIRECTIONS = {
            'DEPART': 'Depart from '
            'CONTINUE': 'Continue on '
            'RIGHT': 'Turn right to '
            'LEFT': 'Turn left to '
            'SLIGHTLY_RIGHT': 'Turn slightly right to '
            'SLIGHTLY_LEFT': 'Turn slightly left to '
            'HARD_RIGHT': 'Turn right hard to '
            'HARD_LEFT': 'Turn left hard to '
            'UTURN_RIGHT': 'U-turn right to '
            'UTURN_LEFT': 'U-turn left to '
        }

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
                route = if leg.route.length < 5 then leg.route else ''
                if leg.mode == 'FERRY'
                    # Don't show number for ferry.
                    route = ''
                if leg.mode == 'WALK'
                    icon = mobility_element.icon
                    if mobility_accessibility_mode == 'wheelchair'
                        text = i18n.t 'transit.mobility_mode.wheelchair'
                    else
                        text = i18n.t 'transit.walk'
                else
                    icon = LEG_MODES[leg.mode].icon
                    text = LEG_MODES[leg.mode].text
                start_time: moment(leg.startTime).format('LT')
                start_location: leg.from.name
                distance: (leg.distance / 1000).toFixed(1) + 'km'
                icon: icon
                transit_color_class: LEG_MODES[leg.mode].color_class
                transit_mode: text
                transit_details: @get_transit_details leg
                route: route
                steps: steps
                has_warnings: !!_.find(steps, (step) -> step.warning)
            )

            end = {
                time: moment(itinerary.endTime).format('LT')
                name: @route.plan.to.name
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

            mobility_mode_text =
                if mobility_accessibility_mode == 'wheelchair'
                    i18n.t 'transit.mobility_mode.wheelchair'
                else
                    i18n.t 'transit.by_foot'

            return {
                skip_route: false
                profile_set: _.keys(p13n.get_accessibility_profile_ids(true)).length
                itinerary: route
                itinerary_choices: @get_itinerary_choices()
                selected_itinerary_index: @selected_itinerary_index
                details_open: @details_open
                current_time: moment(new Date()).format('YYYY-MM-DDTHH:mm')
                mobility_mode_text: mobility_mode_text.toLowerCase()
            }

        parse_steps: (leg) ->
            modes_with_stops = ['BUS', 'TRAM', 'RAIL', 'SUBWAY', 'FERRY']
            steps = []

            if leg.mode in ['WALK', 'BICYCLE', 'CAR']
                for step in leg.steps
                    text = ''
                    warning = null
                    if step.relativeDirection of STEP_DIRECTIONS
                        text += STEP_DIRECTIONS[step.relativeDirection]
                    else
                        text += step.relativeDirection + ' '
                    text += step.streetName
                    if 'alerts' of step and step.alerts.length
                        warning = step.alerts[0].alertHeaderText.someTranslation
                    steps.push(text: text, warning: warning)
            else if leg.mode in modes_with_stops and leg.intermediateStops
                for stop in leg.intermediateStops
                    steps.push(
                        text: stop.name
                        time: moment(stop.arrival).format('LT')
                    )
            else
                steps.push(text: 'No further info.')


            return steps

        get_transit_details: (leg) ->
            if leg.mode == 'SUBWAY'
                return "(#{i18n.t('transit.toward')} #{leg.headsign})"
            else
                return ''

        get_itinerary_choices: ->
            number_of_itineraries = @route.plan.itineraries.length
            start = @itinery_choices_start_index
            stop = Math.min(start + NUMBER_OF_CHOICES_SHOWN, number_of_itineraries)
            return _.range(start, stop)

        switch_itinerary: (event) ->
            event.preventDefault()
            @selected_itinerary_index = $(event.currentTarget).data('index')
            @details_open = true
            @route.switch_itinerary @selected_itinerary_index
            @render()

        switch_end_points: (event) ->
            event.preventDefault()
            # Add switching start and end points functionality here.

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
            # Show time only if it's available.
            time = ''
            if start_time.split('T').length > 1
                time = moment(start_time).format('LT')
            date_start = moment start_time
            date_end = moment end_time
            if not end_time? or date_start.isSame(date_end, 'day')
                date_start = p13n.get_humanized_date start_time
                date_end = ''
            else
                time = ''
                date_start = date_start.format 'D.M'
                date_end = date_end.format 'D.M'
            name: p13n.get_translated_attr(@model.get 'name')
            date_start: date_start
            date_end: date_end
            time: time
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
            start_time = moment @model.get('start_time')
            end_time = moment @model.get('end_time')
            if not @model.get('end_time')? or start_time.isSame(end_time, 'day')
                data.time = moment(@model.get 'start_time').format('LLLL')
            else
                data.time = start_time.format('D.M') + '&mdash;' + end_time.format('D.M')
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
        initialize: (opts) ->
            @filter_transit = opts?.filter_transit or false
        serializeData: ->
            profiles = p13n.get_accessibility_profile_ids @filter_transit
            return {
                profile_set: _.keys(profiles).length
                profiles: p13n.get_profile_elements profiles
            }

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
        onRender: ->
            if @has_data
                @viewpoint_region.show new AccessibilityViewpointView()
        serializeData: ->
            @has_data = @model.get('accessibility_properties')?.length
            # TODO: Check if accessibility profile is set once that data is available.
            profiles = p13n.get_accessibility_profile_ids()
            details = []
            header_classes = []
            short_text = ''

            profile_set = true
            if not _.keys(profiles).length
                profile_set = false
                profiles = p13n.get_all_accessibility_profile_ids()

            shortcomings_pending = false
            if @has_data
                shortcomings = []
                for pid in _.keys profiles
                    shortcoming = accessibility.get_shortcomings(@model.get('accessibility_properties'), pid)
                    if shortcoming.status != 'complete'
                        shortcomings_pending = true
                        break
                    shortcomings.push(shortcoming.messages...)
                # TODO: Fetch real details here once the data is available.
                details = []

            collapse_classes = []
            if @collapsed
                header_classes.push 'collapsed'
            else
                collapse_classes.push 'in'

            seen = []
            _.each shortcomings, (s) =>
                val = p13n.get_translated_attr s
                if val not in seen
                    seen.push val
            shortcomings = seen

            if @has_data and _.keys(profiles).length
                if shortcomings.length
                    if profile_set
                        header_classes.push 'has-shortcomings'
                        short_text = i18n.t('accessibility.shortcoming_count', {count: shortcomings.length})
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
            shortcomings: shortcomings
            details: details
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

    class DetailsView extends SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'details'
        regions:
            'routing_region': '.route-navigation'
            'routing_controls_region': '#routing-controls-region'
            'accessibility_region': '.section.accessibility-section'
            'events_region': '.event-list'
        events:
            'click .back-button': 'user_close'
            'click .icon-icon-close': 'user_close'
            'click .show-more-events': 'show_more_events'
            'click .disabled': 'prevent_disabled_click'
            'click .set-accessibility-profile': 'set_accessibility_profile'
            'click .leave-feedback': 'leave_feedback_on_accessibility'
            'click .section.route-section a.collapser.route': 'toggle_route'
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

        render: ->
            super()
            marker_canvas = @$el.find('#details-marker-canvas').get(0)
            context = marker_canvas.getContext('2d')
            size = 40
            color = app.color_matcher.unit_color(@model) or 'rgb(0, 0, 0)'
            id = 0
            rotation = 90

            marker = new draw.Plant size, color, id, rotation
            marker.draw context

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
                short_text = i18n.t('sidebar.event_count', {count: fetchState.count})
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
            # TODO
            # else if @back == 'browse'
            #     app.commands.execute ''

        prevent_disabled_click: (event) ->
            event.preventDefault()
            event.stopPropagation()

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
            data.provider = @get_translated_provider(@model.get('provider_type'))
            description = data.description
            unless @search_results.isEmpty()
                data.back_to = i18n.t('sidebar.back_to.search')
            MAX_LENGTH = 20
            if description
                words = description.split /[ ]+/
                if words.length > MAX_LENGTH + 1
                    data.description = words[0..MAX_LENGTH].join(' ') + '&hellip;'
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
                    @routing_parameters.set_origin last_pos
                @request_route()
            else
                coordinate_position = new models.CoordinatePosition
                @listenTo p13n, 'position', (pos) =>
                    @request_route()
                @listenTo p13n, 'position_error', =>
                    @show_route_summary null
                if not previous_origin
                    @routing_parameters.set_origin new models.CoordinatePosition
                p13n.request_location @routing_parameters.get_origin()

            @routing_controls_region.show new RoutingControlsView
                model: @routing_parameters
                unit: @model
                user_click_coordinate_position: @user_click_coordinate_position

            @show_route_summary null

        show_route_summary: (route) ->
            @routing_region.show new RoutingSummaryView
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
            if p13n.get_accessibility_mode('mobility') in [
                'wheelchair', 'stroller', 'reduced_mobility'
            ]
                opts.wheelchair = true
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

        set_accessibility_profile: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'

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

    class SearchResultsView extends SMCollectionView
        tagName: 'ul'
        className: 'navigation-element search-results'
        itemView: SearchResultView
        type: 'search'
        initialize: (opts) ->
            @parent = opts.parent
        onRender: ->
            @set_max_height()
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
            @listenTo @collection, 'add', @render
            @listenTo @collection, 'remove', @render
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

        initialize: ->
            $(window).resize @set_max_height
            @listenTo p13n, 'change', @set_activations
            @listenTo p13n, 'user:open', -> @personalisation_button_click()

        personalisation_button_click: (ev) ->
            ev?.preventDefault()
            unless $('#personalisation').hasClass('open')
                @toggle_menu(ev)

        toggle_menu: (ev) ->
            ev?.preventDefault()
            $('#personalisation').toggleClass('open')

        select_on_map: (ev) ->
            # Add here functionality for seleecting user's location from the map.
            ev.preventDefault()

        set_activations: ->
            $list = @$el.find '.personalisations'
            $list.find('li').each (idx, li) =>
                $li = $(li)
                type = $li.data 'type'
                group = $li.data 'group'
                # FIXME
                if group == 'city'
                    activated = p13n.get('city') == type
                else if group == 'mobility'
                    activated = p13n.get_accessibility_mode('mobility') == type
                else if group == 'transport'
                    activated = p13n.get_transport type
                else
                    activated = p13n.get_accessibility_mode type
                if activated
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
            else if group == 'transport'
                p13n.toggle_transport type

        render: (opts) ->
            super opts
            @set_activations()

        onRender: ->
            @set_max_height()

        set_max_height: =>
            # TODO: Refactor this when we get some onDomAppend event.
            # The onRender function that calls set_max_height runs before @el
            # is inserted into DOM. Hence calculating heights and positions of
            # the template elements is currently impossible.
            MOBILE_LAYOUT_BREAKPOINT = 480
            personalisation_header_height = 56
            window_width = $(window).width()
            offset = 0
            if window_width > MOBILE_LAYOUT_BREAKPOINT
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
