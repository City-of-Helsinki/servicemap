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
    paths:
        app: '../js'


requirejs ['app/map', 'app/models', 'app/widgets', 'app/views', 'app/router', 'app/p13n', 'backbone', 'jquery', 'lunr', 'servicetree', 'typeahead', 'L.Control.Sidebar'], (map_stuff, Models, widgets, views, router, p18n, Backbone, $) ->
    app_models =
        service_list: new Models.ServiceList(0)
    controller = new router.ServiceMapController(app_models)
    map_view = new views.AppView app_models.service_list,
        el: document.getElementById 'app-container'

    map_view.render()
    map = map_view.map
    window.map = map
