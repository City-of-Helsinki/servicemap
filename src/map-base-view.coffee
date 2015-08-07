define [
    'backbone',
    'backbone.marionette',
    'i18next',
    'leaflet',
    'leaflet.markercluster',
    'leaflet.snogylop',
    'app/map',
    'app/widgets',
    'app/jade',
    'app/map-state-model'
], (
    Backbone,
    Marionette,
    i18n,
    leaflet,
    markercluster,
    leaflet_snogylop,
    map,
    widgets,
    jade,
    MapStateModel,
) ->

    # TODO: remove duplicates
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city
    ICON_SIZE = 40
    VIEWPOINTS =
        # meters to show everything within in every direction
        singleUnitImmediateVicinity: 200
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8

    _latitudeDeltaFromRadius = (radiusMeters) ->
        (radiusMeters / 40075017) * 360
    _longitudeDeltaFromRadius = (radiusMeters, latitude) ->
        _latitudeDeltaFromRadius(radiusMeters) / Math.cos(L.LatLng.DEG_TO_RAD * latitude)

    boundsFromRadius = (radiusMeters, latLng) ->
        delta = L.latLng _latitudeDeltaFromRadius(radiusMeters),
            _longitudeDeltaFromRadius(radiusMeters, latLng.lat)
        min = L.latLng latLng.lat - delta.lat, latLng.lng - delta.lng
        max = L.latLng latLng.lat + delta.lat, latLng.lng + delta.lng
        L.latLngBounds [min, max]

    class MapBaseView extends Backbone.Marionette.View
        initialize: (@opts, @mapOpts) ->
            @markers = {}
            @units = @opts.units
            @selectedUnits = @opts.selectedUnits
            @selectedPosition = @opts.selectedPosition
            @divisions = @opts.divisions
            @listenTo @units, 'reset', @drawUnits
            @listenTo @units, 'finished', (options) =>
                # Triggered when all of the
                # pages of units have been fetched.
                @drawUnits @units, options
                if @selectedUnits.isSet()
                    @highlightSelectedUnit @selectedUnits.first()

        getProxy: ->
            fn = => map.MapUtils.overlappingBoundingBoxes @map
            getTransformedBounds: fn

        zoomlevelSinglePoint: (latLng, viewpoint) ->
            bounds = boundsFromRadius VIEWPOINTS[viewpoint], latLng
            @map.getBoundsZoom bounds

        mapOptions: {}

        render: ->
            @$el.attr 'id', 'map'

        getMapStateModel: ->
            new MapStateModel @opts

        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            mapStyle = p13n.get 'map_background_layer'
            options =
                style: mapStyle
                language: p13n.getLanguage()
            @map = map.MapMaker.createMap @$el.get(0), options, @mapOptions, @getMapStateModel()
            @map.on 'click', _.bind(@onMapClicked, @)
            @allMarkers = @getFeatureGroup()
            @allMarkers.addTo @map
            @divisionLayer = L.featureGroup()
            @divisionLayer.addTo @map
            @postInitialize()

        onMapClicked: (ev) -> # override

        calculateInitialOptions: ->
            if @selectedPosition.isSet()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
            else if @selectedUnits.isSet()
                zoom: @getMaxAutoZoom()
                center: map.MapUtils.latLngFromGeojson @selectedUnits.first()
            else if @divisions.isSet()
                boundaries = @divisions.map (d) =>
                    new L.GeoJSON d.get('boundary')
                iteratee = (memo, value) => memo.extend value.getBounds()
                bounds = _.reduce boundaries, iteratee, L.latLngBounds([])
                bounds: bounds
            else
                # Default state without selections
                zoom: if (p13n.get('map_background_layer') == 'servicemap') then 10 else 5
                center: DEFAULT_CENTER

        postInitialize: ->
            @_addMouseoverListeners @allMarkers
            @popups = L.layerGroup()
            @popups.addTo @map
            @setInitialView()
            @drawInitialState()

        fitBbox: (bbox) =>
            sw = L.latLng(bbox.slice(0,2))
            ne = L.latLng(bbox.slice(2,4))
            bounds = L.latLngBounds(sw, ne)
            @map.fitBounds bounds

        getMaxAutoZoom: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                7
            else if layer == 'ortographic'
                9
            else
                12


        setInitialView: ->
            if @mapOpts?.bbox?
                @fitBbox @mapOpts.bbox
            else
                opts = @calculateInitialOptions()
                if opts.bounds?
                    @map.fitBounds opts.bounds
                else
                    @map.setView opts.center, opts.zoom

        drawInitialState: =>
            if @selectedPosition.isSet()
                #@showAllUnitsAtHighZoom()
                @handlePosition @selectedPosition.value(),
                    center: false,
                    skipRefit: true,
                    initial: true
            else if @selectedUnits.isSet()
                @drawUnits @units, noRefit: true
            else
                if @units.isSet()
                    @drawUnits @units
                if @divisions.isSet()
                    @divisionLayer.clearLayers()
                    @drawDivisions @divisions

        drawUnits: (units, options) ->
            @allMarkers.clearLayers()
            if units.filters?.bbox?
                if @_skipBboxDrawing
                    return
            unitsWithLocation = units.filter (unit) => unit.get('location')?
            markers = unitsWithLocation.map (unit) => @createMarker(unit, options?.marker)
            latLngs = _(markers).map (m) => m.getLatLng()
            unless options?.keepViewport
                @preAdapt?()
                @map.adaptToLatLngs latLngs
            @allMarkers.addLayers markers

        _combineMultiPolygons: (multiPolygons) ->
            multiPolygons.map (mp) => mp.coordinates[0]

        drawDivisions: (divisions) ->
            geojson =
                coordinates: @_combineMultiPolygons divisions.pluck('boundary')
                type: 'MultiPolygon'
            mp = L.GeoJSON.geometryToLayer geojson,
                null, null,
                invert: true
                color: '#ff8400'
                weight: 3
                strokeOpacity: 1
                fillColor: '#000'
                fillOpacity: 0.2
            @map.adapt()
            mp.addTo @divisionLayer

        handlePosition: (positionObject) ->
            accuracy = location.accuracy
            latLng = map.MapUtils.latLngFromGeojson positionObject
            marker = map.MapUtils.createPositionMarker latLng, accuracy, positionObject.origin()
            marker.addTo @map

        highlightUnselectedUnit: (unit) ->
            # Transiently highlight the unit which is being moused
            # over in search results or otherwise temporarily in focus.
            marker = unit.marker
            popup = marker?.popup
            if popup?.selected
                return
            @_clearOtherPopups popup, clearSelected: true
            if popup?
                $(marker.popup._wrapper).removeClass 'selected'
                popup.setLatLng marker?.getLatLng()
                @popups.addLayer popup

        clusterPopup: (event) ->
            cluster = event.layer
            # Maximum number of displayed names per cluster.
            COUNT_LIMIT = 3
            childCount = cluster.getChildCount()
            names = _.map cluster.getAllChildMarkers(), (marker) ->
                    p13n.getTranslatedAttr marker.unit.get('name')
                .sort()
            data = {}
            overflowCount = childCount - COUNT_LIMIT
            if overflowCount > 1
                names = names[0...COUNT_LIMIT]
                data.overflow_message = i18n.t 'general.more_units',
                    count: overflowCount
            data.names = names
            popuphtml = jade.getTemplate('popup_cluster') data
            popup = @createPopup()
            popup.setLatLng cluster.getBounds().getCenter()
            popup.setContent popuphtml
            cluster.popup = popup
            @map.on 'zoomstart', =>
                @popups.removeLayer popup
            popup

        _addMouseoverListeners: (markerClusterGroup)->
            @bindDelayedPopup markerClusterGroup, null,
                showEvent: 'clustermouseover'
                hideEvent: 'clustermouseout'
                popupCreateFunction: _.bind @clusterPopup, @
            markerClusterGroup.on 'spiderfied', (e) =>
                icon = $(e.target._spiderfied?._icon)
                icon?.fadeTo('fast', 0)

            @_lastOpenedClusterIcon = null
            markerClusterGroup.on 'spiderfied', (e) =>
                # Work around css hover forced opacity showing the
                # clicked cluster which should be hidden.
                if @_lastOpenedClusterIcon
                    L.DomUtil.removeClass @_lastOpenedClusterIcon, 'hidden'
                icon = e.target._spiderfied._icon
                L.DomUtil.addClass icon, 'hidden'
                @_lastOpenedClusterIcon = icon

        getZoomlevelToShowAllMarkers: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                return 8
            else if layer == 'ortographic'
                return 8
            else
                return 14

        getServices: ->
            null

        createClusterIcon: (cluster) ->
            count = cluster.getChildCount()
            serviceIds = {}
            serviceId = null
            markers = cluster.getAllChildMarkers()
            services = @getServices()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                if marker.popup?
                    cluster.on 'remove', (event) =>
                        @popups.removeLayer marker.popup
                if not services or services.isEmpty()
                    root = marker.unit.get('root_services')[0]
                else
                    service = services.find (s) =>
                        s.get('root') in marker.unit.get('root_services')
                    root = service?.get('root') or 50000
                serviceIds[root] = true
            cluster.on 'remove', (event) =>
                if cluster.popup?
                    @popups.removeLayer cluster.popup
            colors = _(serviceIds).map (val, id) =>
                app.colorMatcher.serviceRootIdColor id

            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            iconOpts = {}
            if _(markers).find((m) => m?.unit?.collection?.hasReducedPriority())?
                iconOpts.reducedProminence = true
            new ctor count, ICON_SIZE, colors, null,
                iconOpts

        getFeatureGroup: ->
            L.markerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: (zoom) =>
                    return if (zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()) then 4 else 30
                iconCreateFunction: (cluster) =>
                    @createClusterIcon cluster
                zoomToBoundsOnClick: true

        createMarker: (unit, markerOptions) ->
            id = unit.get 'id'
            if id of @markers
                marker = @markers[id]
                marker.unit = unit
                unit.marker = marker
                return marker

            icon = @createIcon unit, @selectedServices
            marker = widgets.createMarker map.MapUtils.latLngFromGeojson(unit),
                reducedProminence: unit.collection?.hasReducedPriority()
                icon: icon
                zIndexOffset: 100
            marker.unit = unit
            unit.marker = marker
            if @selectMarker?
                @listenTo marker, 'click', @selectMarker

            marker.on 'remove', (event) =>
                marker = event.target
                if marker.popup?
                    @popups.removeLayer marker.popup

            htmlContent = "<div class='unit-name'>#{unit.getText 'name'}</div>"
            popup = @createPopup().setContent htmlContent
            popup.setLatLng marker.getLatLng()
            @bindDelayedPopup marker, popup

            @markers[id] = marker

        _clearOtherPopups: (popup, opts) ->
            @popups.eachLayer (layer) =>
                if layer == popup
                    return
                if opts?.clearSelected or not layer.selected
                    @popups.removeLayer layer

        bindDelayedPopup: (marker, popup, opts) ->
            showEvent = opts?.showEvent or 'mouseover'
            hideEvent = opts?.hideEvent or 'mouseout'
            delay = opts?.delay or 600
            if marker and popup
                marker.popup = popup
                popup.marker = marker

            prevent = false
            createdPopup = null

            popupOn = (event) =>
                unless prevent
                    if opts?.popupCreateFunction?
                        _popup = opts.popupCreateFunction(event)
                        createdPopup = _popup
                    else
                        _popup = popup
                    @_clearOtherPopups _popup, clearSelected: false
                    @popups.addLayer _popup
                prevent = false

            popupOff = (event) =>
                if opts?.popupCreateFunction
                    _popup = createdPopup
                else
                    _popup = popup
                if _popup?
                    if @selectedUnits? and _popup.marker?.unit == @selectedUnits.first()
                        prevent = true
                    else
                        @popups.removeLayer _popup
                _.delay (=> prevent = false), delay

            marker.on hideEvent, popupOff
            marker.on showEvent, _.debounce(popupOn, delay)

        createPopup: (offset) ->
            opts =
                closeButton: false
                autoPan: false
                zoomAnimation: false
                className: 'unit'
                maxWidth: 500
                minWidth: 150
            if offset? then opts.offset = offset
            new widgets.LeftAlignedPopup opts

        createIcon: (unit, services) ->
            color = app.colorMatcher.unitColor(unit) or 'rgb(255, 255, 255)'
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasIcon
            else
                ctor = widgets.PlantCanvasIcon
            iconOptions = {}
            if unit.collection?.hasReducedPriority()
                iconOptions.reducedProminence = true
            icon = new ctor ICON_SIZE, color, unit.id, iconOptions

    return MapBaseView
