requirejsConfig =
    baseUrl: appSettings.static_path + 'vendor'
    paths:
        app: '../js'
    shim:
        'bootstrap':
            deps: ['jquery']
        'backbone':
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'backbone.babysitter':
            deps: ['backbone']
        'typeahead.bundle':
            deps: ['jquery']
        'TweenLite':
            deps: ['CSSPlugin', 'EasePack']
        'leaflet.markercluster':
            deps: ['leaflet']
        'leaflet.activearea':
            deps: ['leaflet']
        'bootstrap-datetimepicker':
            deps: ['bootstrap']
        'bootstrap-tour':
            deps: ['bootstrap']
        'i18next':
            exports: 'i18n'
        'iexhr':
            deps: ['jquery']
        'leaflet.snogylop':
            deps: ['leaflet']
    config:
        'cs!app/p13n': localStorageEnabled: true

requirejs.config requirejsConfig
