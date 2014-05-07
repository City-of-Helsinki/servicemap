requirejs.config
    baseUrl: 'vendor'
    shim:
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        typeahead:
            deps: ['jquery']
        'leaflet.awesome-markers':
            deps: ['leaflet']
        'L.Control.Sidebar':
            deps: ['leaflet']
        TweenLite:
            deps: ['CSSPlugin', 'EasePack']
    paths:
        app: '../js'


requirejs ['app/map', 'app/models', 'app/widgets', 'app/views', 'app/router', 'app/p13n', 'app/map', 'backbone', 'backbone.marionette', 'jquery', 'app/uservoice'], (map_stuff, Models, widgets, views, Router, p13n, MapView, Backbone, Marionette, $, uservoice) ->
    app = new Backbone.Marionette.Application()

    app.addInitializer (opts) ->
        app_models =
            service_list: new Models.ServiceList(0)
        map_view = new MapView()

        map_region = @getRegion 'map'
        map_region.show map_view
        map = map_view.map
        window.map = map

        app_view = new views.AppView
            service_list: app_models.service_list
            map_view: map_view
            el: document.getElementById 'app-container'
        app_view.render()

        router = new Router()
        Backbone.history.start()

    app.addRegions
        sidebar: '#sidebar'
        map: '#app-container'
    window.app = app

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        uservoice.init(p13n.get_language())
