define ->

    # todo: rename?
    class DetailsView extends base.SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'details'
        regions:
            'route_region': '.section.route-section'
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
            'click .set-accessibility-profile': 'open_accessibility_menu'
            'click .leave-feedback': 'leave_feedback_on_accessibility'
            'click .section.main-info .description .body-expander': 'toggle_description_body'
            'show.bs.collapse': 'scroll_to_expanded_section'
        type: 'details'

        initialize: (options) ->
            @INITIAL_NUMBER_OF_EVENTS = 5
            @NUMBER_OF_EVENTS_FETCHED = 20
            @embedded = options.embedded
            @search_results = options.search_results
            @selected_units = options.selected_units
            @selected_position = options.selected_position
            @user_click_coordinate_position = options.user_click_coordinate_position
            @routing_parameters = options.routing_parameters
            @route = options.route
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
            @route_region.show new RouteView
                model: @model
                route: @route
                parent_view: @
                routing_parameters: @routing_parameters
                user_click_coordinate_position: @user_click_coordinate_position
                selected_units: @selected_units
                selected_position: @selected_position

            set_site_title @model.get('name')

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
            event.stopPropagation()
            app.commands.execute 'clearSelectedUnit'
            unless @search_results.isEmpty()
                app.commands.execute 'search'

        prevent_disabled_click: (event) ->
            event.preventDefault()
            event.stopPropagation()

        show_map: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.set_map_active_area_max_height maximize: true

        show_content: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.set_map_active_area_max_height maximize: false

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

        scroll_to_expanded_section: (event) ->
            $container = @$el.find('.content').first()
            # Don't scroll if route leg is expanded.
            return if $(event.target).hasClass('steps')
            $section = $(event.target).closest('.section')
            scrollTo = $container.scrollTop() + $section.position().top
            $('#details-view-container .content').animate(scrollTop: scrollTo)

        open_accessibility_menu: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'


    class EventListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'events'
        itemView: EventListRowView
        initialize: (opts) ->
            @parent = opts.parent


    class EventListRowView extends base.SMItemView
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

