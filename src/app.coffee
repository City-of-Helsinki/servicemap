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
        'leaflet.activearea':
            deps: ['leaflet']
        'bootstrap-datetimepicker':
            deps: ['bootstrap']
        'iexhr':
            deps: ['jquery']

requirejs.config requirejs_config

requirejs ['leaflet'], (L) ->
    # Allow calling original getBounds when needed.
    # (leaflet.activearea overrides getBounds)
    L.Map.prototype._original_getBounds = L.Map.prototype.getBounds

PAGE_SIZE = 1000
DEBUG_STATE = app_settings.debug_state
VERIFY_INVARIANTS = app_settings.verify_invariants

window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not is_internet_explorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

if app_settings.sentry_url
    config = {}
    if app_settings.sentry_disable
        config.shouldSendCallback = -> false
    requirejs ['raven'], (Raven) ->
        Raven.config(app_settings.sentry_url, config).install()
        Raven.setExtraContext git_commit: app_settings.git_commit_id

requirejs ['app/models', 'app/widgets', 'app/views', 'app/p13n', 'app/map', 'app/landing', 'app/color','backbone', 'backbone.marionette', 'jquery', 'app/uservoice', 'app/transit', 'app/debug', 'iexhr'], (Models, widgets, views, p13n, MapView, landing_page, ColorMatcher, Backbone, Marionette, $, uservoice, transit, debug, iexhr) ->

    class AppControl
        constructor: (app_models) ->
            _.extend @, Backbone.Events

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

            @selected_position = app_models.selected_position

            @listenTo p13n, 'change', (path, val) ->
                if path[path.length - 1] == 'city'
                    @_reFetchAllServiceUnits()

            if DEBUG_STATE
                @event_debugger = new debug.EventDebugger @

        at_most_one_is_set: (list) ->
            _.filter(list, (o) -> o.isSet()).length <= 1

        _verify_invariants: ->
            unless @at_most_one_is_set [@services, @search_results]
                return new Error "Active services and search results are mutually exclusive."
            unless @at_most_one_is_set [@selected_position, @selected_units]
                return new Error "Selected positions/units/events are mutually exclusive."
            unless @at_most_one_is_set [@search_results, @selected_position]
                return new Error "Search results & selected position are mutually exclusive."
            return null

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
            if @selected_units.isSet()
                @units.reset [@selected_units.first()]
            else
                @units.reset()

        setUnits: (units) ->
            @services.set []
            @selected_units.reset []
            @units.reset units.toArray()
            # Current cluster based map logic
            # requires batch reset signal.
            @units.trigger 'reset'
        setUnit: (unit) ->
            @services.set []
            @units.reset [unit]
        clearUnits: (opts) ->
            # Only clears selected units, and bbox units,
            # not removed service units nor search results.
            if @search_results.isSet()
                return
            if @services.isSet()
                return
            if opts?.all
                if 'bbox' of @units.filters and @units.length > 1
                    return
                @units.clearFilters()
                @units.reset [], bbox: true
                return
            else if opts?.bbox and 'bbox' not of @units.filters
                return
            @units.clearFilters()
            reset_opts = bbox: true
            if opts?.bbox
                reset_opts.no_refit = true
            if @selected_units.isSet()
                @units.reset [@selected_units.first()], reset_opts
            else
                @units.reset [], reset_opts
        getUnit: (id) ->
            return @units.get id
        addUnitsWithinBoundingBoxes: (bbox_strings) ->
            @units.clearFilters()
            get_bbox = (bbox_strings) =>
                # Fetch bboxes sequentially
                if bbox_strings.length == 0
                    @units.setFilter 'bbox', true
                    @units.trigger 'finished'
                    return
                bbox_string = _.first bbox_strings
                unit_list = new models.UnitList()
                opts = success: (coll, resp, options) =>
                    if unit_list.length
                        @units.add unit_list.toArray()
                    unless unit_list.fetchNext(opts)
                        unit_list.trigger 'finished'
                unit_list.pageSize = PAGE_SIZE
                unit_list.setFilter 'bbox', bbox_string
                unit_list.setFilter 'bbox_srid', 3067
                unit_list.setFilter 'only', 'name,location,root_services'
                # Default exclude filter: statues, wlan hot spots
                unit_list.setFilter 'exclude_services', '25658,25538'
                @listenTo unit_list, 'finished', =>
                    get_bbox _.rest(bbox_strings)
                unit_list.fetch(opts)
            @units.reset [], retain_markers: true
            get_bbox(bbox_strings)

        selectUnit: (unit) ->
            @router.navigate "unit/#{unit.id}/"
            @_select_unit unit
        highlightUnit: (unit) ->
            @units.trigger 'unit:highlight', unit
        _select_unit: (unit) ->
            # For console debugging purposes
            window.debug_unit = unit
            @selected_units.reset [unit], silent: true
            @selected_position.clear()
            department = unit.get 'department'
            municipality = unit.get 'municipality'
            if department? and typeof department == 'object' and \
               municipality? and typeof municipality == 'object'
                 @selected_units.trigger 'reset', @selected_units
            else
                unit.fetch
                    data:
                        include: 'department,municipality,services'
                    success: => @selected_units.trigger 'reset', @selected_units
        _select_unit_by_id: (id) ->
            unit = @getUnit id
            if unit?
                @_select_unit unit
            else
                unit = new Models.Unit id: id
                unit.fetch
                    data:
                        include: 'department,municipality'
                    success: =>
                        @setUnit unit
                        @_select_unit unit
        clearSelectedUnit: ->
            @selected_units.reset []
            @clearUnits
                all: true

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

        selectPosition: (position) ->
            @router.navigate "address/" + position.slugify_address()
            @clearSearchResults()
            @selected_units.reset()
            @selected_position.wrap position

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
            @services.add service
            if @services.length == 1
                # Remove possible units
                # that had been added through
                # other means than service
                # selection.
                @units.reset []
                @units.clearFilters()
                @clearSearchResults()

            if service.has 'ancestors'
                ancestor = @services.find (s) ->
                    s.id in service.get 'ancestors'
                if ancestor?
                    @removeService ancestor
            @_fetchServiceUnits service

        _reFetchAllServiceUnits: ->
            if @services.length > 0
                @units.reset []
                @services.each (s) => @_fetchServiceUnits(s)

        _fetchServiceUnits: (service) ->
            unit_list = new models.UnitList pageSize: PAGE_SIZE
            service.set 'units', unit_list

            unit_list.setFilter 'service', service.id
            unit_list.setFilter 'only', 'name,location,root_services'
            municipality = p13n.get 'city'
            if municipality
                unit_list.setFilter 'municipality', municipality

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
            @selected_position.clear()
            @search_state.set 'input_query', query,
                initial: true
            @search_state.trigger 'change', @search_state,
                initial: true
            if @search_results.query == query
                @search_results.trigger 'ready'
                return
            unless @search_results.isEmpty()
                @search_results.reset []
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

        clearSearchResults: (protect_query=false) ->
            unless protect_query
                @search_state.set 'input_query', null, clearing: true
            if not @search_results.isEmpty()
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
        render_address: (municipality, street_address_slug) ->
            slug = "#{municipality}/#{street_address_slug}"
            plist = models.PositionList.from_slug slug
            @listenTo plist, 'sync', (p) =>
                if p.length == 0
                    throw new Error 'Address slug not found'
                else if p.length == 1
                    position = p.pop()
                else if p.length > 1
                    exact_match = p.filter (pos) ->
                        if slug[slug.length-1].toLowerCase() == pos.get('letter').toLowerCase()
                            return true
                        false
                    if exact_match.length != 1
                        throw new Error 'Too many address matches'
                    position = exact_match.pop()
                @selectPosition position

    class AppRouter extends Backbone.Marionette.AppRouter
        appRoutes:
            '': 'render_home'
            'unit/:id/': 'render_unit'
            'service/:id/': 'render_service'
            'search/?q=:query': 'render_search'
            'address/:municipality/:street_address_slug': 'render_address'

    app = new Backbone.Marionette.Application()
    app.addInitializer (opts) ->
        app_models =
            services: new Models.ServiceList()
            selected_services: new Models.ServiceList()
            units: new Models.UnitList()
            selected_units: new Models.UnitList()
            selected_events: new Models.EventList()
            search_results: new Models.SearchList()
            search_state: new Models.WrappedModel()
            route: new transit.Route()
            routing_parameters: new Models.RoutingParameters()
            selected_position: new Models.WrappedModel()
            user_click_coordinate_position: new Models.WrappedModel()

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

            "selectPosition",

            "selectEvent",
            "clearSelectedEvent",

            "setUnits",
            "setUnit",
            "clearUnits",
            "addUnitsWithinBoundingBoxes"

            "search",
            "clearSearchResults",
            "closeSearch",
        ]
        report_error = (position, command) ->
            e = app_control._verify_invariants()
            if e
                message = "Invariant failed #{position} command #{command}: #{e.message}"
                console.log app_models
                e.message = message
                throw e
        make_interceptor = (comm) ->
            if DEBUG_STATE
                ->
                    console.log "COMMAND #{comm} CALLED"
                    app_control[comm].apply app_control, arguments
                    console.log app_models
            else if VERIFY_INVARIANTS
                ->
                    console.log "COMMAND #{comm} CALLED"
                    report_error "before", comm
                    app_control[comm].apply app_control, arguments
                    report_error "after", comm
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
            route: app_models.route
            routing_parameters: app_models.routing_parameters
            user_click_coordinate_position: app_models.user_click_coordinate_position
            selected_position: app_models.selected_position
        map_view = new MapView
            units: app_models.units
            services: app_models.selected_services
            selected_units: app_models.selected_units
            search_results: app_models.search_results
            navigation_layout: navigation
            user_click_coordinate_position: app_models.user_click_coordinate_position
            selected_position: app_models.selected_position

        window.map_view = map_view
        map = map_view.map

        app_models.route.init app_models.selected_units,
            app_models.selected_position

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
