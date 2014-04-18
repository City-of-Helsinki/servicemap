requirejs.config
    baseUrl: 'vendor'
    shim:
        underscore:
            exports: '_'
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'backbone-tastypie':
            deps: ['backbone']
        typeahead:
            deps: ['jquery']
        'leaflet.awesome-markers':
            deps: ['leaflet']
        'L.Control.Sidebar':
            deps: ['leaflet']
    paths:
        app: '../js'

SMBACKEND_BASE_URL = sm_settings.backend_url + '/'

LANGUAGE = 'fi'

SRV_TEXT =
    fi: 'Palvelut'
    en: 'Services'


requirejs ['app/map', 'app/models', 'app/widgets', 'app/views', 'app/router', 'backbone', 'jquery', 'lunr', 'servicetree', 'typeahead', 'L.Control.Sidebar'], (map_stuff, Models, widgets, views, router, Backbone, $) ->

    app_models =
        service_list: new Models.ServiceList(0)
    controller = new router.ServiceMapController(app_models)
    map_view = new views.AppView app_models.service_list,
        el: document.getElementById 'app-container'

    map_view.render()
    map = map_view.map
    window.map = map
