requirejs_config =
    baseUrl: app_settings.static_path + 'vendor'
    paths:
        app: '../js'
    shim:
        bootstrap:
            deps: ['jquery']
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'typeahead.bundle':
            deps: ['jquery']
        TweenLite:
            deps: ['CSSPlugin', 'EasePack']
        'leaflet.markercluster':
            deps: ['leaflet']
        'bootstrap-datetimepicker':
            deps: ['bootstrap']

requirejs.config requirejs_config

PAGE_SIZE = 1000
DEBUG_STATE = app_settings.debug_state

window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not is_internet_explorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

if app_settings.sentry_url
    requirejs ['raven'], (Raven) ->
        Raven.config(app_settings.sentry_url, {}).install();

requirejs ['app/models', 'app/widgets', 'app/views', 'app/p13n', 'app/map', 'app/landing', 'app/color','backbone', 'backbone.marionette', 'jquery', 'app/uservoice', 'app/transit', 'app/debug'], (Models, widgets, views, p13n, MapView, landing_page, ColorMatcher, Backbone, Marionette, $, uservoice, transit, debug) ->

    class AppControl
        constructor: (app_models) ->
            # Units currently on the map
            @units = app_models.units
            # Services in the cart
            @services = app_models.selected_services
            # Selected units (always of length one)
            @selected_units = app_models.selected_units
            # Selected events (always of length one)
            @selected_events = app_models.selected_events
            @search_results = app_models.search_results
            @search_state = app_models.search_state

            if DEBUG_STATE
                @event_debugger = new debug.EventDebugger @
        reset: () ->
            @units.reset []
            @services.reset []
            @selected_units.reset []
            @selected_events.reset []
            @search_state.clear
                silent: true
            @_resetSearchResults()
        _resetSearchResults: ->
            @search_results.query = null
            @search_results.reset []

        setUnits: (units) ->
            @services.set []
            @selected_units.reset []
            @units.set units.toArray()
            # Current cluster based map logic
            # requires batch reset signal.
            @units.trigger 'reset'
        setUnit: (unit) ->
            @services.set []
            @units.reset [unit]
        getUnit: (id) ->
            return @units.get id
        selectUnit: (unit) ->
            @router.navigate "unit/#{unit.id}/"
            @_select_unit unit
        highlightUnit: (unit) ->
            @units.trigger 'unit:highlight', unit
        _select_unit: (unit) ->
            # For console debugging purposes
            window.debug_unit = unit
            select = (unit) =>
                @selected_units.reset [unit]

            department = unit.get 'department'
            municipality = unit.get 'municipality'
            if department? and typeof department == 'object' and \
               municipality? and typeof municipality == 'object'
                select(unit)
            else
                unit.fetch
                    data:
                        include: 'department,municipality'
                    success: =>
                        select(unit)

        _select_unit_by_id: (id) ->
            unit = @getUnit id
            if unit?
                @_select_unit unit
            else
                unit = new Models.Unit id: id
                @setUnit unit
                unit.fetch
                    data:
                        include: 'department,municipality'
                    success: =>
                        @_select_unit unit

        clearSelectedUnit: ->
            @selected_units.reset []
        selectEvent: (event) ->
            unit = event.get_unit()
            select = =>
                event.set 'unit', unit
                if unit?
                    @setUnit unit
                @selected_events.reset [event]
            if unit?
                unit.fetch
                    success: select
            else
                select()

        clearSelectedEvent: ->
            @selected_events.set []
        removeUnit: (unit) ->
            @units.remove unit
            if unit == @selected_units.first()
                @clearSelectedUnit()
        removeUnits: (units) ->
            @units.remove units,
                silent: true
            @units.trigger 'batch-remove',
                removed: units

        _addService: (service) ->
            @selected_units.reset []
            if @services.isEmpty()
                # Remove possible units
                # that had been added through
                # other means than service
                # selection.
                @units.reset []
                @_resetSearchResults()

            if service.has('ancestors')
                ancestor = @services.find (s) ->
                    s.id in service.get('ancestors')
                if ancestor?
                    @removeService(ancestor)
            @services.add(service)

            unit_list = new models.UnitList pageSize: PAGE_SIZE
            service.set 'units', unit_list

            unit_list.setFilter 'service', service.id
            unit_list.setFilter 'only', 'name,location,root_services'

            opts =
                # todo: re-enable
                #spinner_target: spinner_target
                success: =>
                    has_more = unit_list.fetchNext opts
                    @units.add unit_list.toArray()
                    unless has_more
                        @units.trigger 'finished'

            unit_list.fetch opts

        addService: (service) ->
            if service.has('ancestors')
                @_addService service
            else
                service.fetch
                    data: include: 'ancestors'
                    success: => @_addService service

        removeService: (service_id) ->
            service = @services.get(service_id)
            @services.remove service
            @removeUnits service.get('units').filter (unit) =>
                not @selected_units.get unit

        _search: (query) ->
            @search_state.set 'input_query', query,
                initial: true
            @search_state.trigger 'change', @search_state,
                initial: true
            @search_results.search query,
                success: =>
                    if _paq?
                        _paq.push ['trackSiteSearch', query, false, @search_results.models.length]
                    @setUnits new models.SearchList(
                        @search_results.filter (r) ->
                            r.get('object_type') == 'unit'
                    )
                    @search_results.trigger 'ready'
                    @services.set []
        search: (query) ->
            unless query?
                query = @search_results.query
            if query? and query.length > 0
                @router.navigate "search/?q=#{query}"
                @_search query

        clearSearchResults: ->
            unless @search_results.isEmpty() or not @selected_units.isEmpty()
                @_resetSearchResults()

        closeSearch: ->
            if @selected_units.isEmpty() and @services.isEmpty()
                @home()

        home: ->
            @router.navigate ''
            @reset()

        render_unit: (id) ->
            @_select_unit_by_id id
        render_service: (id) ->
            console.log 'render_service', id
        render_home: ->
            @reset()
        render_search: (query) ->
            @_search query

    class AppRouter extends Backbone.Marionette.AppRouter
        appRoutes:
            '': 'render_home'
            'unit/:id/': 'render_unit'
            'service/:id/': 'render_service'
            'search/?q=:query': 'render_search'

    app = new Backbone.Marionette.Application()
    app.addInitializer (opts) ->
        app_models =
            services: new Models.ServiceList()
            selected_services: new Models.ServiceList()
            units: new Models.UnitList()
            selected_units: new Models.UnitList()
            selected_events: new Models.EventList()
            search_results: new Models.SearchList()
            search_state: new Backbone.Model
            routing_parameters: new Models.RoutingParameters()
            user_click_coordinate_position: new Models.CoordinatePosition
                is_detected: false

        window.debug_app_models = app_models
        app_models.services.fetch
            data:
                level: 0

        app_control = new AppControl app_models

        COMMANDS = [
            "addService",
            "removeService",

            "selectUnit",
            "highlightUnit",
            "clearSelectedUnit",

            "selectEvent",
            "clearSelectedEvent",

            "setUnits",
            "setUnit",

            "search",
            "clearSearchResults",
            "closeSearch",
        ]
        make_interceptor = (comm) ->
            if DEBUG_STATE
                ->
                    console.log "COMMAND #{comm} CALLED"
                    app_control[comm].apply app_control, arguments
                    console.log app_models
            else
                ->
                    app_control[comm].apply app_control, arguments

        for comm in COMMANDS
            @commands.setHandler comm, make_interceptor(comm)

        navigation = new views.NavigationLayout
            service_tree_collection: app_models.services
            selected_services: app_models.selected_services
            search_results: app_models.search_results
            selected_units: app_models.selected_units
            selected_events: app_models.selected_events
            search_state: app_models.search_state
            routing_parameters: app_models.routing_parameters
            user_click_coordinate_position: app_models.user_click_coordinate_position
        map_view = new MapView
            units: app_models.units
            services: app_models.selected_services
            selected_units: app_models.selected_units
            search_results: app_models.search_results
            navigation_layout: navigation
            user_click_coordinate_position: app_models.user_click_coordinate_position

        window.map_view = map_view
        map = map_view.map

        @getRegion('map').show map_view
        @getRegion('navigation').show navigation
        @getRegion('landing_logo').show new views.LandingTitleView
        @getRegion('logo').show new views.TitleView

        personalisation = new views.PersonalisationView
        @getRegion('personalisation').show personalisation

        language_selector = new views.LanguageSelectorView
            p13n: p13n
        @getRegion('language_selector').show language_selector

        service_cart = new views.ServiceCart
            collection: app_models.selected_services
        @getRegion('service_cart').show service_cart

        # The colors are dependent on the currently selected services.
        @color_matcher = new ColorMatcher app_models.selected_services

        f = -> landing_page.clear()
        $('body').one "keydown", f
        $('body').one "click", f
        map_view.map.addOneTimeEventListener
            'zoomstart': f
            'mousedown': f

        router = new AppRouter controller: app_control
        app_control.router = router
        Backbone.history.start
            pushState: true
            root: app_settings.url_prefix

        # Prevent empty anchors from appending a '#' to the URL bar but
        # still allow external links to work.
        $('body').on 'click', 'a', (ev) ->
            target = $(ev.currentTarget)
            if not target.hasClass 'external-link'
                ev.preventDefault()

    app.addRegions
        navigation: '#navigation-region'
        personalisation: '#personalisation'
        language_selector: '#language-selector'
        service_cart: '#service-cart'
        landing_logo: '#landing-logo'
        logo: '#persistent-logo'
        map: '#app-container'

    window.app = app

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        uservoice.init(p13n.get_language())
