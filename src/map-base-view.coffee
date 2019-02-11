define (require) ->
    Backbone         = require 'backbone'
    Marionette       = require 'backbone.marionette'
    i18n             = require 'i18next'
    L                = require 'leaflet'
    markercluster    = require 'leaflet.markercluster'
    leaflet_snogylop = require 'leaflet.snogylop'

    map              = require 'cs!app/map'
    widgets          = require 'cs!app/widgets'
    jade             = require 'cs!app/jade'
    MapStateModel    = require 'cs!app/map-state-model'
    dataviz          = require 'cs!app/data-visualization'
    {getIeVersion}   = require 'cs!app/base'
    {
        vehicleTypes,
        PUBLIC_TRANSIT_MARKER_Z_INDEX_OFFSET,
        SUBWAY_STATION_SERVICE_ID,
        SUBWAY_STATION_STOP_UNIT_DISTANCE
    } = require 'cs!app/transit'

    # TODO: remove duplicates
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER =
        helsinki: [60.171944, 24.941389]
        espoo: [60.19792, 24.708885]
        vantaa: [60.309045, 25.004675]
        kauniainen: [60.21174, 24.729595]

    ICON_SIZE = 40
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8

    L.extend L.LatLng, MAX_MARGIN: 1.0e-7

    class MapBaseView extends Backbone.Marionette.View
        @WORLD_LAT_LNGS: [
            L.latLng([64, 32]),
            L.latLng([64, 21]),
            L.latLng([58, 21]),
            L.latLng([58, 32])
        ]
        getIconSize: ->
            ICON_SIZE
        initialize: ({@opts, @mapOpts, @embedded}) ->
            @markers = {}
            @geometries = {}
            @units = @opts.units
            @stopUnits = @opts.stopUnits
            @transportationStops = @opts.transportationStops
            @selectedUnits = @opts.selectedUnits
            @selectedPosition = @opts.selectedPosition
            @divisions = @opts.divisions
            @statistics = @opts.statistics
            @transitStops = @opts.transitStops

            @listenTo @units, 'reset', @drawUnits
            @listenTo @units, 'finished', (options) =>
                # Triggered when all of the
                # pages of units have been fetched.
                @drawUnits @units, options
                if @selectedUnits.isSet()
                    @highlightSelectedUnit @selectedUnits.first()
            @listenTo @stopUnits, 'finished', (options) =>
                @drawUnits @stopUnits, options, 'stopUnitMarkers', hideSubways = false

        getProxy: ->
            fn = => map.MapUtils.overlappingBoundingBoxes @map
            getTransformedBounds: fn

        mapOptions: {}

        render: ->
            @$el.attr 'id', 'map'

        createMapStateModel: ->
            new MapStateModel @opts, @embedded

        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            mapStyle = p13n.get 'map_background_layer'
            options =
                style: mapStyle
                language: p13n.getLanguage()
            @map = map.MapMaker.createMap @$el.get(0), options, @mapOptions, @createMapStateModel()
            @map.on 'click', _.bind(@onMapClicked, @)
            @allMarkers = @getFeatureGroup()
            @allMarkers.addTo @map
            @stopUnitMarkers = @getFeatureGroup()
            @stopUnitMarkers.addTo @map
            @allGeometries = L.featureGroup()
            @allGeometries.addTo @map
            @divisionLayer = L.featureGroup()
            @divisionLayer.addTo @map
            @visualizationLayer = L.featureGroup()
            @visualizationLayer.addTo @map
            @publicTransitStopsLayer = @createPublicTransitStopsLayer()
            @publicTransitStopsLayer.addTo @map
            @postInitialize()

        createPublicTransitStopsLayer: ->
            L.markerClusterGroup
                showCoverageOnHover: false
                singleMarkerMode: true
                spiderfyOnMaxZoom: false
                zoomToBoundsOnClick: false
                maxClusterRadius: -> 15
                iconCreateFunction: widgets.StopIcon.createClusterIcon

        onMapClicked: (event) -> # override

        getMapBounds: ->
            @map._originalGetBounds()

        calculateInitialOptions: ->
            city = p13n.getCity()
            unless city?
                city = 'helsinki'
            center = DEFAULT_CENTER[city]
            # Default state without selections
            defaults =
                zoom: if (p13n.get('map_background_layer') == 'servicemap') then 10 else 5
                center: center
            if @selectedPosition.isSet()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
            else if @selectedUnits.isSet()
                unit = @selectedUnits.first()
                if unit.get('location')?
                    zoom: @getMaxAutoZoom()
                    center: map.MapUtils.latLngFromGeojson(unit)
                else
                    return defaults
            else if @divisions.isSet()
                boundaries = @divisions.map (d) =>
                    new L.GeoJSON d.get('boundary')
                iteratee = (memo, value) => memo.extend value.getBounds()
                bounds = _.reduce boundaries, iteratee, L.latLngBounds([])
                bounds: bounds
            else
                return defaults

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
            else if @mapOpts?.fitAllUnits == true and not @units.isEmpty()
                latlngs = @units.map (u) -> u.getLatLng()
                bounds = L.latLngBounds latlngs
                @map.fitBounds bounds
            else
                opts = @calculateInitialOptions()
                if opts.bounds?
                    @map.fitBounds opts.bounds
                else
                    @map.setView opts.center, opts.zoom

        drawInitialState: =>
            if @selectedPosition.isSet()
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

        drawUnits: (units, options, layer, hideSubways = true) ->
            cancelled = false
            options?.cancelToken?.addHandler -> cancelled = true
            @allGeometries.clearLayers()

            if units.filters?.bbox?
                if @_skipBboxDrawing
                    return

            unitsWithLocation = units.filter (unit) => unit.get('location')?
            if hideSubways
                unitsWithLocation = unitsWithLocation.filter (unit) => !@isSubwayStation(unit)
            markers = unitsWithLocation.map (unit) => @createMarker(unit, options?.marker)

            unitHasGeometry = (unit) ->
                unit.attributes.geometry?.type in
                    ['LineString', 'MultiLineString', 'Polygon', 'MultiPolygon']

            unitsWithGeometry = units.filter unitHasGeometry

            geometries = unitsWithGeometry.map (unit) => @createGeometry(unit, unit.attributes.geometry)

            latLngs = _(markers).map (m) => m.getLatLng()

            unless options?.keepViewport or (units.length == 1 and unitHasGeometry units.first())
                @preAdapt?()
                @map.adaptToLatLngs latLngs

            if units.length == 1
                @highlightSelectedUnit units.first()

            if layer?
                @[layer].clearLayers()
                @[layer] = @getFeatureGroup()
                @[layer].addLayers markers
                @[layer].addTo @map
            else
                @allMarkers.clearLayers()
                @allMarkers = @getFeatureGroup()
                @allMarkers.addLayers markers
                @allMarkers.addTo @map



        # Prominently highlight the marker whose details are being
        # examined by the user.
        highlightSelectedUnit: (unit) ->
            unless unit?
                return

            marker = unit.marker
            popup = marker?.popup

            unless popup
                return

            popup.selected = true
            @_clearOtherPopups popup, clearSelected: true

            unless @popups.hasLayer popup
                popup.setLatLng marker.getLatLng()
                @popups.addLayer popup

            @listenToOnce unit, 'change:selected', (unit) =>
                unless unit.get 'selected'
                    $(marker?._icon).removeClass 'selected'
                    $(marker?.popup._wrapper).removeClass 'selected'
                    @popups.removeLayer marker?.popup

                    if unit.geometry?
                        @allGeometries.removeLayer(unit.geometry)

            $(marker?._icon).addClass 'selected'
            $(marker?.popup._wrapper).addClass 'selected'

            if unit.geometry?
                @allGeometries.addLayer(unit.geometry)

            # Open the popup for the currently selected unit, if it has stops.
            # currentMarkerWithPopup is used to avoid the sequence:
            # unit selected, popup opened > stop selected, popup opened > map moved, unit popup reopened
            if marker?.stops?.length > 0 and (not @currentMarkerWithPopup or @currentMarkerWithPopup == marker)
                if marker.getPopup()
                    marker.openPopup()
                else
                    @openPublicTransitStops marker, marker.stops

        _combineMultiPolygons: (multiPolygons) ->
            multiPolygons.map (mp) => mp.coordinates[0]

        drawDivisionGeometry: (geojson) ->
            mp = L.GeoJSON.geometryToLayer geojson,
                null, null,
                invert: true
                worldLatLngs: MapBaseView.WORLD_LAT_LNGS
                color: '#ff8400'
                weight: 3
                strokeOpacity: 1
                fillColor: '#000'
                fillOpacity: 0.2
            @map.adapt()
            mp.addTo @divisionLayer

        drawDivisionsAsGeoJSONWithDataAttached: (divisions, statistics, statisticsPath) ->
            type = dataviz.getStatisticsType(statisticsPath.split('.')[0])
            layer = dataviz.getStatisticsLayer(statisticsPath.split('.')[1])
            domainMax = Math.max(Object.keys(statistics.attributes).map( (id) ->
                comparisonKey = statistics.attributes[id]?[type]?[layer]?.comparison
                if isNaN(+statistics.attributes[id]?[type]?[layer]?[comparisonKey])
                then 0
                else +statistics.attributes[id][type][layer][comparisonKey]
            )...)
            app.vent.trigger 'statisticsDomainMax', domainMax
            geojson = divisions.map (division) =>
                geometry:
                    coordinates: division.get('boundary').coordinates
                    type: 'MultiPolygon'
                type: 'Feature'
                properties:
                    _.extend({}, statistics.attributes[division.get('origin_id')]?[type]?[layer], {name: division.get('name')})
            L.geoJson(geojson,
                weight: 1
                color: '#000'
                fillColor: '#000'
                style: (feature) ->
                    fillOpacity: +(feature.properties?.normalized? && feature.properties.normalized)
                onEachFeature: (feature, layer) ->
                    popupOpts =
                        className: 'position'
                        offset: L.point 0, -15
                    popup = L.popup(popupOpts)
                        .setContent jade.template('statistic-popup', feature.properties)
                    layer.bindPopup popup
            ).addTo(@map);

        drawDivisions: (divisions) ->
            geojson =
                coordinates: @_combineMultiPolygons divisions.pluck('boundary')
                type: 'MultiPolygon'
            @drawDivisionGeometry geojson

        drawDivision: (division) ->
            unless division?
                return
            @drawDivisionGeometry division.get('boundary')

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

            # Work around css hover forced opacity showing the
            # clicked cluster which should be hidden.
            markerClusterGroup.on 'spiderfied', (e) =>
                icon = e.target._spiderfied._icon
                if icon
                    $(icon).fadeTo('fast', 0)
                    L.DomUtil.addClass icon, 'hidden'

            markerClusterGroup.on 'unspiderfied', (e) =>
                icon = e.cluster._icon
                if icon
                    L.DomUtil.removeClass icon, 'hidden'

        getZoomlevelToShowAllMarkers: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                return 8
            else if layer == 'ortographic'
                return 8
            else
                return 14

        createClusterIcon: (cluster) ->
            markers = cluster.getAllChildMarkers()

            markers.forEach (marker) =>
                if marker.unit? and marker.popup?
                    cluster.on 'remove', (event) =>
                        @popups.removeLayer marker.popup

            cluster.on 'remove', (event) =>
                if cluster.popup?
                    @popups.removeLayer cluster.popup

            clusterIconClass = if MARKER_POINT_VARIANT then widgets.PointCanvasClusterIcon else widgets.CanvasClusterIcon

            iconSpecs = markers
                .filter (marker) -> marker.unit
                .map (marker) =>
                    if @isSubwayStation marker.unit
                        type: 'stop'
                        vehicleType: vehicleTypes.SUBWAY
                    else
                        type: 'normal'
                        color: app.colorMatcher.unitColor marker.unit

            iconOpts = {
                className: 'no-tabindex'
            }
            if _(markers).find((marker) => marker?.unit?.collection?.hasReducedPriority())?
                iconOpts.reducedProminence = true

            new clusterIconClass iconSpecs, @getIconSize(), iconOpts

        getFeatureGroup: ->
            featureGroup = L.markerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: (zoom) =>
                    return if (zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()) then 4 else 30
                iconCreateFunction: (cluster) =>
                    # Avoid having to zoom to max zoom level on clicking a cluster with positioned icons
                    cluster._bounds._northEast.lat = cluster._bounds._southWest.lat
                    cluster._bounds._northEast.lng = cluster._bounds._southWest.lng
                    @createClusterIcon cluster
                zoomToBoundsOnClick: true
            featureGroup._getExpandedVisibleBounds = ->
                bounds = featureGroup._map._originalGetBounds()
                sw = bounds._southWest
                ne = bounds._northEast
                latDiff = if L.Browser.mobile then 0 else Math.abs(sw.lat - ne.lat) / 4
                lngDiff = if L.Browser.mobile then 0 else Math.abs(sw.lng - ne.lng) / 4
                return new L.LatLngBounds(
                    new L.LatLng(sw.lat - latDiff, sw.lng - lngDiff, true),
                    new L.LatLng(ne.lat + latDiff, ne.lng + lngDiff, true))
            featureGroup

        createMarker: (unit, markerOptions) ->
            id = unit.get 'id'
            if id of @markers
                marker = @markers[id]
                marker.unit = unit
                unit.marker = marker
                return marker

            latLng = map.MapUtils.latLngFromGeojson(unit)
            icon = @createIcon unit
            markerOptions =
                icon: icon
                reducedProminence: unit.collection?.hasReducedPriority()
                zIndexOffset: 100
                keyboard: false #Set keyboard functionality off

            if icon.className
                markerOptions.className = icon.className

            marker = widgets.createMarker latLng, markerOptions

            marker.unit = unit
            unit.marker = marker
            if @selectMarker?
                marker.on 'click', @selectMarker, @

            marker.on 'remove', (event) =>
                marker = event.target
                if marker.popup?
                    @popups.removeLayer marker.popup

            popup = @createPopup unit
            popup.setLatLng marker.getLatLng()
            @bindDelayedPopup marker, popup

            if @isSubwayStation(unit)
                marker.setZIndexOffset(PUBLIC_TRANSIT_MARKER_Z_INDEX_OFFSET)
                marker.stops = @transitStops
                    .filter (stop) ->
                        stop.get('vehicleType') == vehicleTypes.SUBWAY
                    .filter (stop) ->
                        stopLatLng = L.latLng stop.get('lat'), stop.get('lon')
                        marker.getLatLng().distanceTo(stopLatLng) < SUBWAY_STATION_STOP_UNIT_DISTANCE

            @markers[id] = marker

        isSubwayStation: (unit) ->
            _.some unit?.get('services'), (service) ->
                service == SUBWAY_STATION_SERVICE_ID or
                service.id == SUBWAY_STATION_SERVICE_ID

        openPublicTransitStops: ->

        createGeometry: (unit, geometry, opts) ->
            id = unit.get 'id'
            if id of @geometries
                geometry = @geometries[id]
                unit.geometry = geometry
                return geometry

            geometry = L.geoJson geometry, style: (feature) =>
                weight: 8
                color: '#cc2121'
                opacity: 0.6

            unit.geometry = geometry

            @geometries[id] = geometry


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

        createPopup: (unit, opts, offset) ->
            popup = @createPopupWidget opts, offset
            if unit?
                htmlContent = "<div class='unit-name'>#{unit.getText 'name'}</div>"
                popup.setContent htmlContent
            popup

        createPopupWidget: (opts, offset) ->
            defaults =
                closeButton: false
                autoPan: false
                zoomAnimation: false
                className: 'unit'
                maxWidth: 500
                minWidth: 150

            if opts?
                opts = _.defaults opts, defaults
            else
                opts = defaults

            if offset?
                opts.offset = offset

            new widgets.LeftAlignedPopup opts

        createIcon: (unit) ->
            if @needsSubwayIcon unit
                return widgets.StopIcon.createSubwayIcon()

            color = app.colorMatcher.unitColor(unit)

            iconClass = if MARKER_POINT_VARIANT
                widgets.PointCanvasIcon
            else
                widgets.PlantCanvasIcon

            iconOptions = {}
            if unit.collection?.hasReducedPriority()
                iconOptions.reducedProminence = true

            new iconClass @getIconSize(), color, unit.id, iconOptions

        needsSubwayIcon: -> false

    return MapBaseView
