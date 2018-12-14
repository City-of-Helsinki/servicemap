define (require) ->
    _                               = require 'underscore'
    leaflet                         = require 'leaflet'
    Backbone                        = require 'backbone'
    Marionette                      = require 'backbone.marionette'
    markercluster                   = require 'leaflet.markercluster'
    leaflet_activearea              = require 'leaflet.activearea'
    i18n                            = require 'i18next'
    URI                             = require 'URI'

    widgets                         = require 'cs!app/widgets'
    models                          = require 'cs!app/models'
    p13n                            = require 'cs!app/p13n'
    jade                            = require 'cs!app/jade'
    MapBaseView                     = require 'cs!app/map-base-view'
    TransitMapMixin                 = require 'cs!app/transit-map'
    map                             = require 'cs!app/map'
    MapStateModel                   = require 'cs!app/map-state-model'
    ToolMenu                        = require 'cs!app/views/tool-menu'
    LocationRefreshButtonView       = require 'cs!app/views/location-refresh-button'
    PublicTransitStopsView          = require 'cs!app/views/public-transit-stops'
    SMPrinter                       = require 'cs!app/map-printer'
    MeasureTool                     = require 'cs!app/measure-tool'
    {mixOf}                         = require 'cs!app/base'
    {getIeVersion}                  = require 'cs!app/base'
    {isFrontPage}                   = require 'cs!app/util/navigation'
    dataviz                         = require 'cs!app/data-visualization'
    {TransitStoptimesList, typeToName, vehicleTypes,
    PUBLIC_TRANSIT_MARKER_Z_INDEX_OFFSET, SUBWAY_STATION_STOP_UNIT_DISTANCE} = require 'cs!app/transit'

    ICON_SIZE = 40
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city

    class MapView extends mixOf MapBaseView, TransitMapMixin
        tagName: 'div'
        initialize: (@opts, @mapOpts) ->
            super @opts, @mapOpts

            @selectedServices = @opts.selectedServices
            @selectedServiceNodes = @opts.selectedServiceNodes
            @searchResults = @opts.searchResults
            #@listenTo @units, 'add', @drawUnits
            # @selectedPosition = @opts.selectedPosition
            @selectedDivision = @opts.selectedDivision

            @publicTransitStopsCache = {}
            { @transitStops } = @opts

            @userPositionMarkers =
                accuracy: null
                position: null
                clicked: null

            @listenTo @divisions, 'finished', (cancelToken, statisticsPath) =>
                cancelToken.set 'status', 'rendering'
                [type, layer] = statisticsPath.split '.', 1
                lr = @drawDivisionsAsGeoJSONWithDataAttached(
                    @divisions
                    @statistics
                    statisticsPath)
                @visualizationLayer.addLayer lr
                @closeAddressPopups()
                app.request 'addDataLayer', 'statistics_layer', statisticsPath, lr._leaflet_id

                cancelToken.complete()

            @dataLayers = @opts.dataLayers

            [@selectedServices, @selectedServiceNodes].forEach (serviceItemList) =>
                @listenTo serviceItemList, 'add', =>
                    if @selectedServices.size() + @selectedServiceNodes.size() == 1
                        @markers = {}
                @listenTo serviceItemList, 'remove', =>
                    if @selectedServices.size() + @selectedServiceNodes.size() == 0
                        @markers = {}

            @listenTo @selectedDivision, 'change:value', (model) =>
                @divisionLayer.clearLayers()
                @drawDivision model.value()

            @listenTo @units, 'unit:highlight', @highlightUnselectedUnit
            @listenTo @units, 'batch-remove', @removeUnits
            @listenTo @units, 'remove', @removeUnit
            @listenTo @selectedUnits, 'reset', @handleSelectedUnit
            @listenTo p13n, 'position', @handlePosition

            @listenTo @dataLayers, 'add', @addDataLayer
            @listenTo @dataLayers, 'remove', @removeDataLayer

            if @selectedPosition.isSet()
                @listenTo @selectedPosition.value(), 'change:radiusFilter', @radiusFilterChanged
            @listenTo @selectedPosition, 'change:value', (wrapper, value) =>
                previous = wrapper.previous 'value'
                if previous?
                    @stopListening previous
                if value?
                    @listenTo value, 'change:radiusFilter', @radiusFilterChanged
                @handlePosition value, center: true

            MapView.setMapActiveAreaMaxHeight
                maximize:
                    @selectedPosition.isEmpty() and @selectedUnits.isEmpty()

            @initializeTransitMap
                route: @opts.route
                selectedUnits: @selectedUnits
                selectedPosition: @selectedPosition

            @printer = new SMPrinter @
            @previousBoundingBoxes = null

            @listenTo @transitStops, 'reset', ->
                @drawPublicTransitStops()

        onMapClicked: (ev) ->
            if @measureTool and @measureTool.isActive or p13n.get('statistics_layer')
                return
            unless @hasClickedPosition? then @hasClickedPosition = false
            if @hasClickedPosition
                @infoPopups.clearLayers()
                @map.removeLayer @userPositionMarkers['clicked']
                @hasClickedPosition = false
            else
                if @pendingPosition?
                    position = @pendingPosition
                else
                    position = new models.CoordinatePosition
                        isDetected: false
                        isPending: false
                position.set 'location',
                    coordinates: [ev.latlng.lng, ev.latlng.lat]
                    accuracy: 0
                    type: 'Point'
                if @pendingPosition?
                    @pendingPosition = null
                    $('#map').css 'cursor', 'auto'
                else
                    position.set 'name', null
                    @hasClickedPosition = true
                @handlePosition position, initial: true

        requestLocation: (position) ->
            $('#map').css 'cursor', 'crosshair'
            @pendingPosition = position

        radiusFilterChanged: (position, radius, {cancelToken}) ->
            @divisionLayer.clearLayers()
            unless radius?
                return
            latLng = L.GeoJSON.geometryToLayer(position.get('location'))
            poly = new widgets.CirclePolygon latLng.getLatLng(), radius, {invert: true, stroke: false, worldLatLngs: MapBaseView.WORLD_LAT_LNGS}
            poly.circle.options.fill = false
            poly.addTo @divisionLayer
            poly.circle.addTo @divisionLayer

        handleSelectedUnit: (units, options) ->
            if units.isEmpty()
                # The previously selected unit might have been a bbox unit.
                @_removeBboxMarkers @map.getZoom(), map.MapUtils.getZoomlevelToShowAllMarkers()
                MapView.setMapActiveAreaMaxHeight maximize: true
                return
            unit = units.first()

            bounds = unit.geometry?.getBounds()
            if bounds
                @map.setMapView
                    bounds: bounds
            else
                latLng = unit.marker?.getLatLng()
                if latLng?
                    @map.adaptToLatLngs [latLng]

            unless unit.hasBboxFilter()
                @_removeBboxMarkers()
                @_skipBboxDrawing = false
            _.defer => @highlightSelectedUnit unit

        handlePosition: (positionObject, opts) ->
            # TODO: clean up this method
            unless positionObject?
                for key in ['clicked', 'address']
                    layer = @userPositionMarkers[key]
                    if layer then @map.removeLayer layer

            isSelected = positionObject == @selectedPosition.value()

            key = positionObject?.origin()
            if key != 'detected'
                @infoPopups.clearLayers()

            prev = @userPositionMarkers[key]
            if prev then @map.removeLayer prev

            if (key == 'address') and @userPositionMarkers.clicked?
                @map.removeLayer @userPositionMarkers.clicked
            if (key == 'clicked') and isSelected and @userPositionMarkers.address?
                @map.removeLayer @userPositionMarkers.address

            location = positionObject?.get 'location'
            unless location then return

            accuracy = location.accuracy
            accuracyMarker = L.circle latLng, accuracy, weight: 0

            latLng = map.MapUtils.latLngFromGeojson positionObject
            marker = map.MapUtils.createPositionMarker latLng, accuracy, positionObject.origin()
            marker.position = positionObject
            marker.on 'click', => app.request 'selectPosition', positionObject
            if isSelected or opts?.center
                @map.refitAndAddMarker marker
            else
                marker.addTo @map

            @userPositionMarkers[key] = marker

            if isSelected
                @infoPopups.clearLayers()

            popup = @createPositionPopup positionObject, marker

            if not positionObject?.isDetectedLocation() or
                @selectedUnits.isEmpty() and (
                    @selectedPosition.isEmpty() or
                    @selectedPosition.value() == positionObject)
                pop = => @infoPopups.addLayer popup
                unless positionObject.get 'preventPopup'
                    if isSelected or (opts?.initial and not positionObject.get('preventPopup'))
                        pop()
                        if isSelected
                            $(popup._wrapper).addClass 'selected'

            positionObject.popup = popup

        width: ->
            @$el.width()
        height: ->
            @$el.height()

        removeUnits: (options) ->
            @allMarkers.clearLayers()
            @allGeometries.clearLayers()
            @drawUnits @units
            unless @selectedUnits.isEmpty()
                @highlightSelectedUnit @selectedUnits.first()
            if @units.isEmpty()
                @showAllUnitsAtHighZoom()

        removeUnit: (unit, units, options) ->
            if unit.marker?
                @allMarkers.removeLayer unit.marker
                delete unit.marker

            if unit.geometry?
                @allGeometries.removeLayer unit.geometry
                delete unit.geometry

        createPositionPopup: (positionObject, marker) ->
            latLng = map.MapUtils.latLngFromGeojson(positionObject)
            address = positionObject.humanAddress()
            unless address
                address = i18n.t 'map.retrieving_address'
            if positionObject == @selectedPosition.value()
                popupContents =
                    (ctx) =>
                        "<div class=\"unit-name\">#{ctx.name}</div>"
                offsetY = switch positionObject.origin()
                    when 'detected' then 10
                    when 'address' then 10
                    else 38
                popup = @createPopup(null, null, L.point(0, offsetY))
                    .setContent popupContents
                        name: address
                    .setLatLng latLng
            else
                popupContents =
                    (ctx) =>
                        ctx.detected = positionObject?.isDetectedLocation()
                        $popupEl = $ jade.template 'position-popup', ctx
                        $popupEl.on 'click', (e) =>
                            unless positionObject == @selectedPosition.value()
                                e.stopPropagation()
                                @listenTo positionObject, 'reverse-geocode', =>
                                    app.request 'selectPosition', positionObject
                                marker.closePopup()
                                @infoPopups.clearLayers()
                                @map.removeLayer positionObject.popup
                                if positionObject.isReverseGeocoded()
                                    positionObject.trigger 'reverse-geocode'

                        $popupEl[0]
                offsetY = switch positionObject.origin()
                    when 'detected' then -53
                    when 'clicked' then -15
                    when 'address' then -50
                offset = L.point 0, offsetY
                popupOpts =
                    closeButton: false
                    className: 'position'
                    autoPan: false
                    offset: offset
                    autoPanPaddingTopLeft: L.point 30, 80
                    autoPanPaddingBottomRight: L.point 30, 80
                popup = L.popup(popupOpts)
                    .setLatLng latLng
                    .setContent popupContents
                        name: address

            success = =>
                popup.setContent popupContents
                    name: positionObject.humanAddress()
            error = =>
                popup.setContent popupContents
                    name: i18n.t('map.unknown_address')
            positionObject.reverseGeocode?().done(success).fail(error)
            popup

        createStatisticsPopup: (positionObject, statistic) ->
            latLng = map.MapUtils.latLngFromGeojson(positionObject)
            popupContents =
                (ctx) =>
                    $popupEl = $ jade.template 'statistic-popup', ctx
                    $popupEl[0]
            popupOpts =
                closeButton: true
                className: 'statistic'
            popup = L.popup(popupOpts)
                .setLatLng latLng
                .setContent popupContents
                    name: statistic.name
                    value: statistic.value
                    proportion: statistic.proportion

        selectMarker: (event) ->
            marker = event.target
            unit = marker.unit
            @currentMarkerWithPopup = null
            app.request 'selectUnit', unit, {}

        drawPublicTransitStops: ->
            @transitStops.forEach (stop) =>
                if @publicTransitStopsCache[stop.id]
                    return

                @publicTransitStopsCache[stop.id] = stop

                latLng = L.latLng stop.get('lat'), stop.get('lon')

                vehicleType = stop.get 'vehicleType'
                marker = new widgets.StopMarker latLng,
                    stopId: stop.id
                    vehicleType: vehicleType
                    autoPanPaddingBottomRight: L.point(30, 30)
                    zIndexOffset: PUBLIC_TRANSIT_MARKER_Z_INDEX_OFFSET
                marker.stops = [stop]

                # Subway stops are not drawn on the map.
                # Instead, link the stops to the existing subway station unit markers,
                # and add click handlers.
                if vehicleType == vehicleTypes.SUBWAY
                    stopUnitMarkers = _.values @markers
                        .filter (unitMarker) => @isSubwayStation(unitMarker.unit)
                        .filter (unitMarker) ->
                            latLng.distanceTo(unitMarker.getLatLng()) < SUBWAY_STATION_STOP_UNIT_DISTANCE

                    stopUnitMarkers
                        .forEach (stopUnitMarker) =>
                            stopUnitMarker.stops = stopUnitMarker.stops or []
                            stopUnitMarker.stops.push stop
                else
                    @setPublicTransitClickHandler marker
                    marker.addTo @publicTransitStopsLayer

            if @selectedUnits.first()?.marker?.stops
                @highlightSelectedUnit @selectedUnits.first()

        setPublicTransitClickHandler: (marker) ->
            # Avoid duplicate handlers by removing existing ones
            marker.off 'click', @onPublicTransitStopClick, @
            marker.on 'click', @onPublicTransitStopClick, @

        onPublicTransitStopClick: (event) ->
            marker = event.target
            stops = marker.stops
            @openPublicTransitStops marker, stops

        openPublicTransitStops: (marker, stops) ->
            if stops.length == 0
                console.error 'No stops found for marker', { marker }
                return

            @currentMarkerWithPopup = marker

            ids = _.map stops, (stop) -> stop.get 'gtfsId'
            collection = new TransitStoptimesList null, { ids }
            view = new PublicTransitStopsView { collection }

            marker
                .bindPopup view.el,
                    className: 'public-transit-stops-popup'
                    closeButton: true
                    closeOnClick: true
                    maxWidth: 304
                    minWidth: 304
                    offset: L.point(183, 80)
                .openPopup()

        getCenteredView: ->
            if @selectedPosition.isSet()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
            else if @selectedUnits.isSet()
                center: map.MapUtils.latLngFromGeojson @selectedUnits.first()
                zoom: Math.max @getMaxAutoZoom(), @map.getZoom()
            else
                null

        resetMap: ->
            # With different projections the base layers cannot
            # be changed on a live map.
            unless isFrontPage()
                window.location.reload true
                return
            uri = URI window.location.href
            uri.addSearch reset: 1
            window.location.href = uri.href()

        handleP13nChange: (path, newVal) ->
            if path[0] != 'map_background_layer'
                return

            oldLayer = @map._baseLayer
            oldCrs = @map.crs

            mapStyle = p13n.get 'map_background_layer'
            {layer: newLayer, crs: newCrs} = map.MapMaker.makeBackgroundLayer style: mapStyle

            if newCrs.code != oldCrs.code
                @resetMap()
                return

            @map.addLayer newLayer
            newLayer.bringToBack()
            @map.removeLayer oldLayer
            @map._baseLayer = newLayer
            @drawUnits @units

        clearPublicTransitStopsLayer: ->
            @publicTransitStopsLayer.clearLayers()
            @publicTransitStopsCache = {}

        addMapActiveArea: ->
            @map.setActiveArea 'active-area'
            MapView.setMapActiveAreaMaxHeight
                maximize: @selectedUnits.isEmpty() and @selectedPosition.isEmpty()

        initializeMap: ->
            @setInitialView()
            window.debugMap = map
            @listenTo p13n, 'change', @handleP13nChange
            # The line below is for debugging without clusters.
            # @allMarkers = L.featureGroup()
            @popups = L.layerGroup()
            @infoPopups = L.layerGroup()

            #L.control.scale(imperial: false).addTo(@map);

            L.control.zoom(
                position: 'bottomright'
                zoomInText: "<span class=\"icon-icon-zoom-in\"></span><span class=\"sr-only\">#{i18n.t('assistive.zoom_in')}</span>"
                zoomOutText: "<span class=\"icon-icon-zoom-out\"></span><span class=\"sr-only\">#{i18n.t('assistive.zoom_out')}</span>").addTo @map

            new widgets.ControlWrapper(new LocationRefreshButtonView(), position: 'bottomright').addTo @map
            new widgets.ControlWrapper(new ToolMenu(), position: 'bottomright').addTo @map

            @popups.addTo @map
            @infoPopups.addTo @map

            @debugGrid = L.layerGroup().addTo(@map)
            @debugCircles = {}

            @_addMapMoveListeners()

            # If the user has allowed location requests before,
            # try to get the initial location now.
            if p13n.getLocationRequested()
                p13n.requestLocation()

            @previousZoomlevel = @map.getZoom()
            @drawInitialState()

        _removeBboxMarkers: (zoom, zoomLimit) ->
            unless @markers?
                return
            if @markers.length == 0
                return
            if zoom? and zoomLimit?
                if zoom >= zoomLimit
                    return
            @_skipBboxDrawing = true
            if @selectedServices.isSet() or @selectedServiceNodes.isSet()
                return

            toRemove = _.filter @markers, (m) =>
                unit = m?.unit
                ret = unit?.collection?.hasReducedPriority() and not unit?.get 'selected'
            @units?.clearFilters 'bbox'
            @allMarkers.removeLayers toRemove
            @_clearOtherPopups null, null

        _addMapMoveListeners: ->
            markersZoomLimit = map.MapUtils.getZoomlevelToShowAllMarkers()
            publicTransitStopsZoomLimit = map.MapUtils.getZoomlevelToShowPublicTransitStops()
            @map.on 'zoomanim', (data) =>
                @_skipBboxDrawing = false
                @_removeBboxMarkers data.zoom, markersZoomLimit
            @map.on 'zoomend', =>
                @_removeBboxMarkers @map.getZoom(), markersZoomLimit
                @ensurePublicTransitStopVisibility @map.getZoom(), publicTransitStopsZoomLimit
            @map.on 'moveend', =>
                unitAndStopMarkers = @allMarkers.getLayers().concat(@publicTransitStopsLayer.getLayers())

                # TODO: cleaner way to prevent firing from refit
                if @skipMoveend
                    @skipMoveend = false
                    return
                @showAllUnitsAtHighZoom()
                @updatePublicTransitStops()

        postInitialize: ->
            @addMapActiveArea()
            @initializeMap()
            @_addMouseoverListeners @allMarkers

            @publicTransitStopsLayer.on 'clusterclick', @onPublicTransitStopsClusterClick, @

        onPublicTransitStopsClusterClick: (event) ->
            marker = event.layer
            markers = marker.getAllChildMarkers()
            stopLists = _.pluck markers, 'stops'
            stops = _.flatten stopLists

            @openPublicTransitStops marker, stops

        @mapActiveAreaMaxHeight: =>
            screenWidth = $(window).innerWidth()
            screenHeight = $(window).innerHeight()
            Math.max(220, Math.min(screenWidth * 0.4, screenHeight * 0.3))

        preAdapt: =>
            MapView.setMapActiveAreaMaxHeight()

        @setMapActiveAreaMaxHeight: (options) =>
            # Sets the height of the map shown in views that have a slice of
            # map visible on mobile.
            defaults = maximize: false
            options = options or {}
            _.extend defaults, options
            options = defaults
            if $(window).innerWidth() <= appSettings.mobile_ui_breakpoint
                height = MapView.mapActiveAreaMaxHeight()
                $activeArea = $ '.active-area'
                if options.maximize
                    $activeArea.css 'height', 'auto'
                    $activeArea.css 'bottom', 0
                else
                    $activeArea.css 'height', height
                    $activeArea.css 'bottom', 'auto'
            else
                $('.active-area').css 'height', 'auto'
                $('.active-area').css 'bottom', 0

        refitBounds: ->
            @skipMoveend = true
            @map.fitBounds @allMarkers.getBounds(),
                maxZoom: @getMaxAutoZoom()
                animate: true

        fitItinerary: (layer) ->
            @map.fitBounds layer.getBounds(),
                paddingTopLeft: [20,20]
                paddingBottomRight: [20,20]

        ensurePublicTransitStopVisibility: (zoom, zoomLimit) ->
            if zoom < zoomLimit
                @clearPublicTransitStopsLayer()
                @transitStops.reset()

        updatePublicTransitStops: ->
            if @map.getZoom() < map.MapUtils.getZoomlevelToShowPublicTransitStops()
                return
            app.request 'requestPublicTransitStops'

        showAllUnitsAtHighZoom: ->
            if @map.getZoom() < map.MapUtils.getZoomlevelToShowAllMarkers()
                @previousBoundingBoxes = null
                return
            if getIeVersion()
                return
            if @selectedUnits.isSet() and not @selectedUnits.first().collection?.filters?.bbox?
                return
            if @selectedServices.isSet()
                return
            if @selectedServiceNodes.isSet()
                return
            if @searchResults.isSet()
                return

            transformedBounds = map.MapUtils.overlappingBoundingBoxes @map
            bboxes = transformedBounds.map (bbox) -> "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
            bboxstring = bboxes.join(';')

            if @previousBoundingBoxes == bboxstring
                return

            @previousBoundingBoxes = bboxstring

            if @mapOpts?.level?
                level = @mapOpts.level
                delete @mapOpts.level

            app.request 'addUnitsWithinBoundingBoxes', bboxes, level

        print: ->
            @printer.printMap true

        addDataLayer: (layer) ->
            if (layer.get('layerName') == 'heatmap_layer')
                lr = map.MapUtils.createHeatmapLayer(layer.get 'dataId')
                @visualizationLayer.addLayer lr
                layer.set('leafletId', lr._leaflet_id)

        removeDataLayer: (layer) ->
            @visualizationLayer.removeLayer(layer.get('leafletId'))

        turnOnMeasureTool: ->
            @closeAddressPopups()
            unless @measureTool
                @measureTool = new MeasureTool(@map)
            @measureTool.activate()
            # Disable selecting units when measuring
            _.values(@markers).map (marker) =>
                marker.off 'click', @selectMarker
                # Enable measuring when clicking a unit marker
                marker.on 'click', @measureTool.measureAddPoint

        turnOffMeasureTool: ->
            @measureTool.deactivate()
            # Re-enable selecting units when measuring
            _.values(@markers).map (marker) =>
                marker.on 'click', @selectMarker
                marker.off 'click', @measureTool.measureAddPoint

        closeAddressPopups: ->
            if @hasClickedPosition
                @infoPopups.clearLayers()
                @map.removeLayer @userPositionMarkers['clicked']
                @hasClickedPosition = false

        needsSubwayIcon: (unit) ->
            @isSubwayStation unit

    MapView
