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

requirejs.config requirejs_config


window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not is_internet_explorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

requirejs ['app/map', 'app/models', 'app/widgets', 'app/views', 'app/router', 'app/p13n', 'app/map', 'backbone', 'backbone.marionette', 'jquery', 'app/uservoice'], (map_stuff, Models, widgets, views, Router, p13n, MapView, Backbone, Marionette, $, uservoice) ->

    class AppControl
        constructor: (options) ->
            @units = options.unit_collection
            @services = options.service_collection
        setUnits: (units) ->
            @units = units
        addService: (service) ->
            @services.add(service)
            units_to_add = new models.UnitList()
            units_to_add.fetch
                data:
                    service: service.id
                    page_size: 100
                    only: 'name,location'
#                spinner_target: spinner_target
                success: =>
                    @units.add units_to_add.models
                    @services.trigger 'change'
                    console.log @units
                    console.log @services

    app = new Backbone.Marionette.Application()

    app.addInitializer (opts) ->
        app_models =
            service_list: new Models.ServiceList()
            selected_services: new Models.ServiceList()
            shown_units: new Models.UnitList()
        map_view = new MapView()

        map = map_view.map
        window.map = map

        app_state = new views.AppState
            service_list: app_models.service_list
            selected_services: app_models.selected_services
            map_view: map_view

        app_control = new AppControl
            unit_collection: app_models.shown_units
            service_collection: app_models.selected_services

        #@commands.setHandler "addService", (service )-> app_control.addService(service)

        service_sidebar_view = new views.ServiceSidebarView
            parent: app_state
            service_tree_collection: app_models.service_list
            selected_services: app_models.selected_services

        app_state.service_sidebar = service_sidebar_view

        (@getRegion 'map').show map_view
        (@getRegion 'navigation').show service_sidebar_view
        (@getRegion 'landing_logo').show new views.LandingTitleView
        (@getRegion 'logo').show new views.TitleView

        customization = new views.CustomizationLayout
        (@getRegion 'customization').show customization
        customization.cart.show new views.ServiceCart
            collection: app_state.selected_services
            app: app_state
        customization.language.show new views.LanguageSelectorView
            p13n: p13n

        f = -> app_state.clear_landing_page()
        $('body').one "keydown", f
        map_view.map.addOneTimeEventListener
            'zoomstart': f
            'mousedown': f

        router = new Router()
        Backbone.history.start()

    app.addRegions
        navigation: '#navigation-region'
        customization: '#customization'
        landing_logo: '#landing-logo'
        logo: '#persistent-logo'
        map: '#app-container'
    window.app = app

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        uservoice.init(p13n.get_language())
