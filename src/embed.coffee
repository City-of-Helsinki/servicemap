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
    config:
        'app/p13n': localStorageEnabled: false

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

requirejs [
    'app/models',
    'app/p13n',
    'app/color',
    'app/map-base-view'
    'app/map',
    'app/views/embedded-title',
    'backbone',
    'backbone.marionette',
    'jquery',
    'iexhr',
    'i18next',
    'URI',
    'bootstrap',
    'app/router',
    'app/control',
    'app/embedded-views',
    'app/widgets'
],
(
    models,
    p13n,
    ColorMatcher,
    BaseMapView,
    map,
    TitleView,
    Backbone,
    Marionette,
    $,
    iexhr,
    i18n,
    URI,
    Bootstrap,
    Router,
    BaseControl,
    TitleBarView,
    widgets
) ->

    app = new Backbone.Marionette.Application()
    window.app = app

    fullUrl = ->
        currentUri = URI window.location.href
        currentUri.segment(0, "").toString()

    class EmbeddedMapView extends BaseMapView
        mapOptions:
            dragging: true
            touchZoom: true
            scrollWheelZoom: false
            doubleClickZoom: true
            boxZoom: false
        postInitialize: ->
            super()
            zoom = L.control.zoom
                position: 'bottomright'
                zoomInText: "<span class=\"icon-icon-zoom-in\"></span>"
                zoomOutText: "<span class=\"icon-icon-zoom-out\"></span>"
            logo = new widgets.ControlWrapper(new TitleView(href: fullUrl()), position: 'bottomleft', autoZIndex: false)
            zoom.addTo @map
            logo.addTo @map
            @allMarkers.on 'click', (l) =>
                root = URI(window.location.href).host()
                if l.layer?.unit?
                    window.open "http://#{root}/unit/" + l.layer.unit.get('id')
                else
                    window.open fullUrl()
            @allMarkers.on 'clusterclick', =>
                window.open fullUrl()

        clusterPopup: (event) ->
            cluster = event.layer
            childCount = cluster.getChildCount()
            popup = @createPopup()
            html = """
                <div class='servicemap-prompt'>
                    #{i18n.t 'embed.click_prompt_move'}
                </div>
            """
            popup.setContent html
            popup.setLatLng cluster.getBounds().getCenter()
            popup
        createPopup: (unit) ->
            popup = L.popup offset: L.point(0, 30), closeButton: false
            if unit?
                htmlContent = """
                    <div class='unit-name'>#{unit.getText 'name'}</div>
                    <div class='servicemap-prompt'>#{i18n.t 'embed.click_prompt'}</div>
                """
                popup.setContent htmlContent
            popup
        getFeatureGroup: ->
            L.markerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: (zoom) =>
                    return if (zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()) then 4 else 30
                iconCreateFunction: (cluster) =>
                    @createClusterIcon cluster
                zoomToBoundsOnClick: false
        handlePosition: (positionObject) ->
            accuracy = location.accuracy
            latLng = map.MapUtils.latLngFromGeojson positionObject
            marker = map.MapUtils.createPositionMarker latLng, accuracy, positionObject.origin(), clickable: true
            marker.position = positionObject
            popup = L.popup offset: L.point(0, 40), closeButton: false
            name = positionObject.humanAddress()
            popup.setContent "<div class='unit-name'>#{name}</div>"
            marker.bindPopup popup
            marker.addTo @map
            @map.adapt()
            marker.openPopup()
            marker.on 'click', => window.open fullUrl()

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
                mapView = new EmbeddedMapView appState, mapOptions, true
                app.getRegion('map').show mapView
                control.setMapProxy mapView.getProxy()

        baseRoot = "#{appSettings.url_prefix}embed"
        root = baseRoot + '/'
        if !(window.history and history.pushState)
          rootRegexp = new RegExp baseRoot + '\/?'
          url = window.location.href
          url = url.replace rootRegexp, '/'
          currentUri = URI url
          currentUri
          router.routeEmbedded currentUri
        else
            Backbone.history.start
                pushState: true, root: root

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
