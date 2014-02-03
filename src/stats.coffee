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

requirejs ['app/map', 'app/models', 'jquery', 'L.Control.Sidebar'], (map_stuff, models, $) ->
    map = map_stuff.map

    div_list = new models.AdministrativeDivisionList
    div_type_list = new models.AdministrativeDivisionTypeList
    div_type_list.fetch
        success: (list) ->
            list.forEach (m) ->
                console.log m.attributes

    div_list.on 'add', (m) ->
        console.log m.attributes
        layer = L.geoJson m.get('boundary'),
            style:
                weight: 2
                fillOpacity: 0.1
        layer.bindPopup "#{m.get('name').fi} (tunnus #{m.get('origin_id')})"
        map.addLayer layer

    div_list.fetch
        data:
            type__type: 'neighborhood'
            limit: 1000
            parent__ocd_id: 'ocd-division/country:fi/kunta:helsinki'
            geometry: true
