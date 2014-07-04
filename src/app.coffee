requirejs_config =
    baseUrl: 'vendor'
    paths:
        app: '../js'
    shim:
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        typeahead:
            deps: ['jquery']
        TweenLite:
            deps: ['CSSPlugin', 'EasePack']
        'leaflet.markercluster':
            deps: ['leaflet']

requirejs.config requirejs_config

PAGE_SIZE = 1000

window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not is_internet_explorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

requirejs ['app/models', 'app/widgets', 'app/views', 'app/router', 'app/p13n', 'app/map', 'app/landing', 'app/color','backbone', 'backbone.marionette', 'jquery', 'app/uservoice', 'app/transit'], (Models, widgets, views, Router, p13n, MapView, landing_page, ColorMatcher, Backbone, Marionette, $, uservoice, transit) ->

    class AppControl
        constructor: (options) ->
            # Units currently on the map
            @units = options.unit_collection
            # Services in the cart
            @services = options.service_collection
            # Selected units (always of length one)
            @selected_units = options.selected_units
            # Selected events (always of length one)
            @selected_events = options.selected_events
            @search_results = options.search_results
            window.debug_search_results = @search_results
        setUnits: (units) ->
            @services.set []
            @units.reset units.toArray()
        setUnit: (unit) ->
            @services.set []
            @units.reset [unit]
        selectUnit: (unit) ->
            # For console debugging purposes
            window.debug_unit = unit

            select = (unit) =>
                @selected_units.reset [unit]

            if unit.has('department') and unit.has('municipality')
                select(unit)
            else
                unit.fetch
                    data:
                        include: 'department,municipality'
                    success: =>
                        select(unit)
        clearSelectedUnit: ->
            @selected_units.set []
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
            if @services.isEmpty()
                # Remove possible units
                # that had been added through
                # other means than service
                # selection.
                @units.reset []
                @search_results.set []

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
            @removeUnits service.get('units').toArray()

        search: (query) ->
            @search_results.search query,
                success: =>
                    if _paq?
                        _paq.push ['trackSiteSearch', query, false, @search_results.models.length]
                    @setUnits new models.SearchList(
                        @search_results.filter (r) ->
                            r.get('object_type') == 'unit'
                    )
                    @services.set []
        clearSearch: ->
            unless @search_results.isEmpty()
                @search_results.reset []

    app = new Backbone.Marionette.Application()

    app.addInitializer (opts) ->
        app_models =
            service_list: new Models.ServiceList()
            selected_services: new Models.ServiceList()
            selected_units: new Models.UnitList()
            selected_events: new Models.EventList()
            shown_units: new Models.UnitList()
            search_results: new Models.SearchList()

        app_models.service_list.fetch
            data:
                level: 0

        app_control = new AppControl
            unit_collection: app_models.shown_units
            service_collection: app_models.selected_services
            selected_units: app_models.selected_units
            selected_events: app_models.selected_events
            search_results: app_models.search_results

        @commands.setHandler "addService", (service) -> app_control.addService service
        @commands.setHandler "removeService", (service_id) -> app_control.removeService service_id
        @commands.setHandler "selectUnit", (unit) -> app_control.selectUnit unit
        @commands.setHandler "clearSelectedUnit", -> app_control.clearSelectedUnit()
        @commands.setHandler "selectEvent", (event) -> app_control.selectEvent event
        @commands.setHandler "clearSelectedEvent", -> app_control.clearSelectedEvent()
        @commands.setHandler "setUnits", (units) -> app_control.setUnits units
        @commands.setHandler "setUnit", (unit) -> app_control.setUnit unit
        @commands.setHandler "search", (query) -> app_control.search query
        @commands.setHandler "clearSearch", -> app_control.clearSearch()

        navigation = new views.NavigationLayout
            service_tree_collection: app_models.service_list
            selected_services: app_models.selected_services
            search_results: app_models.search_results
            selected_units: app_models.selected_units
            selected_events: app_models.selected_events
        map_view = new MapView
            units: app_models.shown_units
            services: app_models.selected_services
            selected_units: app_models.selected_units
            search_results: app_models.search_results
            navigation_layout: navigation

        map = map_view.map

        @getRegion('map').show map_view
        @getRegion('navigation').show navigation
        @getRegion('landing_logo').show new views.LandingTitleView
        @getRegion('logo').show new views.TitleView

        customization = new views.CustomizationLayout
        @getRegion('customization').show customization

        customization.cart.show new views.ServiceCart
            collection: app_models.selected_services

        personalisation = new views.PersonalisationView
        @getRegion('personalisation').show personalisation

        language_selector = new views.LanguageSelectorView
            p13n: p13n
        @getRegion('language_selector').show language_selector

        # The colors are dependent on the currently selected services.
        @color_matcher = new ColorMatcher app_models.selected_services

        f = -> landing_page.clear()
        $('body').one "keydown", f
        $('body').one "click", f
        map_view.map.addOneTimeEventListener
            'zoomstart': f
            'mousedown': f

        router = new Router()
        Backbone.history.start()

    app.addRegions
        navigation: '#navigation-region'
        customization: '#customization'
        personalisation: '#personalisation'
        language_selector: '#language-selector'
        landing_logo: '#landing-logo'
        logo: '#persistent-logo'
        map: '#app-container'

    window.app = app

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        uservoice.init(p13n.get_language())
