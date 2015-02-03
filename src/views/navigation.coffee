define ->

    class NavigationLayout extends base.SMLayout
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
            @route = options.route
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
            @contents.on('show', @update_max_heights)
            $(window).resize @update_max_heights
            @listenTo(app.vent, 'landing-page-cleared', @set_max_height)
        update_max_heights: =>
            @set_max_height()
            current_view_type = @contents.currentView?.type
            MapView.set_map_active_area_max_height
                maximize: not current_view_type or current_view_type == 'search'
        set_max_height: =>
            # Set the sidebar content max height for proper scrolling.
            $limited_element = @$el.find('.limit-max-height')
            return unless $limited_element.length
            max_height = $(window).innerHeight() - $limited_element.offset().top
            $limited_element.css 'max-height': max_height
            @$el.find('.map-active-area').css 'padding-bottom', MapView.map_active_area_max_height()
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
            MapView.set_map_active_area_max_height maximize: true

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
                        route: @route
                        parent: @
                        routing_parameters: @routing_parameters
                        search_results: @search_results
                        selected_units: @selected_units
                        selected_position: @selected_position
                        user_click_coordinate_position: @user_click_coordinate_position
                when 'event'
                    view = new EventView
                        model: @selected_events.first()
                when 'position'
                    view = new PositionDetailsView
                        model: @selected_position.value()
                        route: @route
                        selected_position: @selected_position
                        routing_parameters: @routing_parameters
                        user_click_coordinate_position: @user_click_coordinate_position
                else
                    @opened = false
                    view = null
                    @contents.close()

            # Update personalisation icon visibility.
            if type in ['browse', 'search', 'details', 'event', 'position']
                $('#personalisation').addClass('hidden')
            else
                $('#personalisation').removeClass('hidden')

            if view?
                @contents.show view, {animation_type: @get_animation_type(type)}
                @open_view_type = type
                @opened = true
            unless type == 'details'
                # TODO: create unique titles for routes that require it
                app.vent.trigger 'site-title:change', null

    class NavigationHeaderView extends base.SMLayout
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

    class BrowseButtonView extends base.SMItemView
        template: 'navigation-browse'
