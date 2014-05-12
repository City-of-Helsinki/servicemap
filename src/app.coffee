requirejs.config
    baseUrl: 'vendor'
    shim:
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        typeahead:
            deps: ['jquery']
        TweenLite:
            deps: ['CSSPlugin', 'EasePack']
    paths:
        app: '../js'


requirejs ['app/map', 'app/models', 'app/widgets', 'app/views', 'app/router', 'app/p13n', 'app/map', 'backbone', 'backbone.marionette', 'jquery', 'app/uservoice'], (map_stuff, Models, widgets, views, Router, p13n, MapView, Backbone, Marionette, $, uservoice) ->
    app = new Backbone.Marionette.Application()

    app.addInitializer (opts) ->
        app_models =
            service_list: new Models.ServiceList()
            selected_services: new Models.ServiceList()
        map_view = new MapView()

        map = map_view.map
        window.map = map

        app_state = new views.AppState
            service_list: app_models.service_list
            selected_services: app_models.selected_services
            map_view: map_view

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
