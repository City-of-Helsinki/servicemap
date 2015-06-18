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
    'app/embedded-views'
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
        drawUnits: (units, opts) ->
            unitsWithLocation = units.filter (unit) => unit.get('location')?
            markers = unitsWithLocation.map (unit) => @createMarker(unit)
            _.each markers, (marker) => @allMarkers.addLayer marker
            if opts.zoom? and opts.zoom
                if units.length == 1
                    level = @zoomlevelSinglePoint markers[0].getLatLng(),
                        'singleUnitImmediateVicinity'
                    @map.setView markers[0].getLatLng(), level, animate: false
                else
                    @map.fitBounds L.latLngBounds(_.map(markers, (m) => m.getLatLng()))
        fitBbox: (bbox) =>
            sw = L.latLng(bbox.slice(0,2))
            ne = L.latLng(bbox.slice(2,4))
            bounds = L.latLngBounds(sw, ne)
            @map.fitBounds bounds
            @showAllUnitsAtHighZoom()

        showAllUnitsAtHighZoom: ->
            transformedBounds = map.MapUtils.overlappingBoundingBoxes @map
            bboxes = []
            for bbox in transformedBounds
                bboxes.push "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
            app.commands.execute 'addUnitsWithinBoundingBoxes', bboxes

    appState =
        # TODO handle pagination
        divisions: new models.AdministrativeDivisionList
        units: new models.UnitList null, pageSize: 500

    class EmbedControl
        constructor: (@state) ->
            _.extend @, Backbone.Events
        addUnitsWithinBoundingBoxes: (bboxStrings) =>
            @state.units.clearFilters()
            getBbox = (bboxStrings) =>
                # Fetch bboxes sequentially
                if bboxStrings.length == 0
                    @state.units.setFilter 'bbox', true
                    @state.units.trigger 'finished'
                    return
                bboxString = _.first bboxStrings
                unitList = new models.UnitList()
                opts = success: (coll, resp, options) =>
                    if unitList.length
                        @state.units.add unitList.toArray()
                    unless unitList.fetchNext(opts)
                        unitList.trigger 'finished'
                unitList.pageSize = PAGE_SIZE
                unitList.setFilter 'bbox', bboxString
                layer = p13n.get 'map_background_layer'
                unitList.setFilter 'bbox_srid', if layer == 'servicemap' then 3067 else 3879
                unitList.setFilter 'only', 'name,location,root_services'
                # Default exclude filter: statues, wlan hot spots
                unitList.setFilter 'exclude_services', '25658,25538'
                @listenTo unitList, 'finished', =>
                    getBbox _.rest(bboxStrings)
                unitList.fetch(opts)
            @state.units.reset [], retainMarkers: true
            getBbox(bboxStrings)

    app.addInitializer (opts) ->
        # The colors are dependent on the currently selected services.
        @colorMatcher = new ColorMatcher
        mapview = new EmbeddedMapView
        app.getRegion('map').show mapview
        router = new Router app, appState, mapview
        Backbone.history.start
            pushState: true
            root: appSettings.url_prefix
        control = new EmbedControl appState
        @commands.setHandler 'addUnitsWithinBoundingBoxes', (bboxes) => control.addUnitsWithinBoundingBoxes(bboxes)

    app.addRegions
        navigation: '#navigation-region'
        map: '#app-container'

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        $appContainer = $('#app-container')
        $appContainer.attr 'class', p13n.get('map_background_layer')
        $appContainer.addClass 'embed'
