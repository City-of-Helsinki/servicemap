requirejsConfig =
    baseUrl: appSettings.static_path + 'vendor'
    paths:
        app: '../js'
    shim:
        bootstrap:
            deps: ['jquery']
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'leaflet.markercluster':
            deps: ['leaflet']
        'iexhr':
            deps: ['jquery']

requirejs.config requirejsConfig

PAGE_SIZE = 1000

# TODO: move to common file??
window.getIeVersion = ->
    isInternetExplorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not isInternetExplorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

if appSettings.sentry_url
    config = {}
    if appSettings.sentry_disable
        config.shouldSendCallback = -> false
    requirejs ['raven'], (Raven) ->
        Raven.config(appSettings.sentry_url, config).install()
        Raven.setExtraContext git_commit: appSettings.git_commit_id

requirejs [
    'app/models',
    'app/p13n',
    'app/color',
    'app/map-base-view'
    'app/map',
    'backbone',
    'backbone.marionette',
    'jquery',
    'iexhr',
    'bootstrap',
    'app/router',
    'app/control',
    'app/embedded-views',
],
(
    models,
    p13n,
    ColorMatcher,
    BaseMapView,
    map,
    Backbone,
    Marionette,
    $,
    iexhr,
    Bootstrap,
    Router,
    BaseControl,
    TitleBarView
) ->

    app = new Backbone.Marionette.Application()
    window.app = app

    class EmbeddedMapView extends BaseMapView
        mapOptions:
            dragging: false
            touchZoom: false
            scrollWheelZoom: false
            doubleClickZoom: false
            boxZoom: false

    appState =
        # TODO handle pagination
        divisions: new models.AdministrativeDivisionList
        units: new models.UnitList null, pageSize: 500
        selectedUnits: new models.UnitList()
        selectedPosition: new models.WrappedModel()
        selectedDivision: new models.WrappedModel()
        selectedServices: new models.ServiceList()
        searchResults: new models.SearchList [], pageSize: appSettings.page_size

    appState.services = appState.selectedServices
    window.appState = appState

    app.addInitializer (opts) ->
        # The colors are dependent on the currently selected services.
        @colorMatcher = new ColorMatcher
        control = new BaseControl appState
        router = new Router
            controller: control
            makeMapView: (mapOptions) =>
                mapView = new EmbeddedMapView appState, mapOptions
                app.getRegion('map').show mapView
                control.setMapProxy mapView.getProxy()
        Backbone.history.start
            pushState: true
            root: "#{appSettings.url_prefix}embed/"
        @commands.setHandler 'addUnitsWithinBoundingBoxes', (bboxes) =>
            control.addUnitsWithinBoundingBoxes(bboxes)

    app.addRegions
        navigation: '#navigation-region'
        map: '#app-container'

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        $appContainer = $('#app-container')
        $appContainer.attr 'class', p13n.get('map_background_layer')
        $appContainer.addClass 'embed'
