define [
    'leaflet',
    'backbone',
    'backbone.marionette',
    'leaflet.markercluster',
    'leaflet.activearea',
    'i18next',
    'URI',
    'cs!app/widgets',
    'cs!app/models',
    'cs!app/p13n',
    'cs!app/jade',
    'cs!app/map-base-view',
    'cs!app/transit-map',
    'cs!app/map',
    'cs!app/base',
    'cs!app/map-state-model',
    'cs!app/views/tool-menu',
    'cs!app/views/location-refresh-button',
    'cs!app/util/navigation'
], (
    leaflet,
    Backbone,
    Marionette,
    markercluster,
    leaflet_activearea,
    i18n,
    URI,
    widgets,
    models,
    p13n,
    jade,
    MapBaseView,
    TransitMapMixin,
    map,
    {mixOf: mixOf, getIeVersion: getIeVersion},
    MapStateModel,
    ToolMenu,
    LocationRefreshButtonView,
    {isFrontPage: isFrontPage}
) ->

    ICON_SIZE = 40
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city

    class MapView extends mixOf MapBaseView, TransitMapMixin
        tagName: 'div'
        initialize: (@opts, @mapOpts) ->
            super @opts, @mapOpts
            @selectedServices = @opts.services
            @searchResults = @opts.searchResults
            #@listenTo @units, 'add', @drawUnits
            # @selectedPosition = @opts.selectedPosition
            @selectedDivision = @opts.selectedDivision
            @userPositionMarkers =
                accuracy: null
                position: null
                clicked: null

            @listenTo @selectedServices, 'add', (service, collection) =>
                if collection.size() == 1
                    @markers = {}
            @listenTo @selectedServices, 'remove', (model, collection) =>
                if collection.size() == 0
                    @markers = {}

            @listenTo @selectedDivision, 'change:value', (model) =>
                @divisionLayer.clearLayers()
                @drawDivision model.value()

            @listenTo @units, 'unit:highlight', @highlightUnselectedUnit
            @listenTo @units, 'batch-remove', @removeUnits
            @listenTo @units, 'remove', @removeUnit
            @listenTo @selectedUnits, 'reset', @handleSelectedUnit
            @listenTo p13n, 'position', @handlePosition

            if @selectedPosition.isSet()
                @listenTo @selectedPosition.value(), 'change:radiusFilter', @radiusFilterChanged
            @listenTo @selectedPosition, 'change:value', (wrapper, value) =>
                previous = wrapper.previous 'value'
                if previous?
                    @stopListening previous
                if value?
                    @listenTo value, 'change:radiusFilter', @radiusFilterChanged
                @handlePosition value, center: true
            @listenTo app.vent, 'mapview-activearea:maximize', =>
                MapView.setMapActiveAreaMaxHeight maximize: true
            @listenTo app.vent, 'mapview-activearea:minimize', =>
                MapView.setMapActiveAreaMaxHeight maximize: false

            MapView.setMapActiveAreaMaxHeight
                maximize:
                    @selectedPosition.isEmpty() and @selectedUnits.isEmpty()

            @initializeTransitMap
                route: @opts.route
                selectedUnits: @selectedUnits
                selectedPosition: @selectedPosition

            #$(window).resize => _.defer(_.bind(@recenter, @))

        onMapClicked: (ev) ->
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

        radiusFilterChanged: (position, radius) ->
            @divisionLayer.clearLayers()
            unless radius?
                return
            latLng = L.GeoJSON.geometryToLayer(position.get('location'))
            poly = new widgets.CirclePolygon latLng.getLatLng(), radius, {invert: true, stroke: false}
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
            latLng = unit.marker?.getLatLng()
            if latLng?
                fn = =>
                    @map.adaptToLatLngs [latLng]
                if window.isVirtualKeyboardOpen
                    @listenTo app.vent, 'virtual-keyboard:hidden', => fn()
                else
                    fn()
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
            marker.on 'click', => app.commands.execute 'selectPosition', positionObject
            if isSelected or opts?.center
                TIMEOUT = 1000
                fn = _.once =>
                    @map.refitAndAddMarker marker
                if window.isVirtualKeyboardOpen
                    @listenTo app.vent, 'virtual-keyboard:hidden', => fn()
                    _.delay fn, TIMEOUT
                else
                    fn()
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
            @drawUnits @units
            unless @selectedUnits.isEmpty()
                @highlightSelectedUnit @selectedUnits.first()
            if @units.isEmpty()
                @showAllUnitsAtHighZoom()

        removeUnit: (unit, units, options) ->
            if unit.marker?
                @allMarkers.removeLayer unit.marker
                delete unit.marker

        getServices: ->
            @selectedServices

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
                                    app.commands.execute 'selectPosition', positionObject
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

            positionObject.reverseGeocode?().done =>
                popup.setContent popupContents
                    name: positionObject.humanAddress()
            popup

        selectMarker: (event) ->
            marker = event.target
            unit = marker.unit
            app.commands.execute 'selectUnit', unit

        drawUnit: (unit, units, options) ->
            location = unit.get 'location'
            if location?
                marker = @createMarker unit
                @allMarkers.addLayer marker

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
            @map.removeLayer oldLayer
            @map._baseLayer = newLayer
            @drawUnits @units

        @$mapActiveAreaDomElement: null
        addMapActiveArea: ->
            @map.setActiveArea 'active-area'
            MapView.$mapActiveAreaDomElement = $ @map.getViewport()
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
            if @selectedServices.isSet()
                return
            toRemove = _.filter @markers, (m) =>
                unit = m?.unit
                ret = unit?.collection?.hasReducedPriority() and not unit?.get 'selected'
            app.commands.execute 'clearFilters', 'bbox'
            @allMarkers.removeLayers toRemove
            @_clearOtherPopups null, null

        _addMapMoveListeners: ->
            zoomLimit = map.MapUtils.getZoomlevelToShowAllMarkers()
            @map.on 'zoomanim', (data) =>
                @_skipBboxDrawing = false
                @_removeBboxMarkers data.zoom, zoomLimit
            @map.on 'zoomend', =>
                @_removeBboxMarkers @map.getZoom(), zoomLimit
            @map.on 'moveend', =>
                # TODO: cleaner way to prevent firing from refit
                if @skipMoveend
                    @skipMoveend = false
                    return
                @showAllUnitsAtHighZoom()

        postInitialize: ->
            @addMapActiveArea()
            @initializeMap()
            @_addMouseoverListeners @allMarkers

        @mapActiveAreaMaxHeight: =>
            screenWidth = $(window).innerWidth()
            screenHeight = $(window).innerHeight()
            Math.min(screenWidth * 0.4, screenHeight * 0.3)

        preAdapt: =>
            MapView.setMapActiveAreaMaxHeight()

        @setMapActiveAreaMaxHeight: (options) =>
            # Sets the height of the map shown in views that have a slice of
            # map visible on mobile.
            defaults = maximize: false
            options = options or {}
            _.extend defaults, options
            options = defaults
            maximize = false
            if $(window).innerWidth() <= appSettings.mobile_ui_breakpoint
                maximize = options.maximize
            @$mapActiveAreaDomElement?.toggleClass 'maximized', maximize

        recenter: ->
            view = @getCenteredView()
            unless view?
                return
            @map.setView view.center, view.zoom, pan: duration: 0.5

        refitBounds: ->
            @skipMoveend = true
            @map.fitBounds @allMarkers.getBounds(),
                maxZoom: @getMaxAutoZoom()
                animate: true

        fitItinerary: (layer) ->
            @map.fitBounds layer.getBounds(),
                paddingTopLeft: [20,20]
                paddingBottomRight: [20,20]

        showAllUnitsAtHighZoom: ->
            if $(window).innerWidth() <= appSettings.mobile_ui_breakpoint
                return
            if @map.getZoom() >= map.MapUtils.getZoomlevelToShowAllMarkers()
                if @selectedUnits.isSet() and not @selectedUnits.first().collection?.filters?.bbox?
                    return
                if @selectedServices.isSet()
                    return
                if @searchResults.isSet()
                    return
                transformedBounds = map.MapUtils.overlappingBoundingBoxes @map
                bboxes = []
                for bbox in transformedBounds
                    bboxes.push "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
                if @mapOpts.level?
                    level = @mapOpts.level
                    delete @mapOpts.level
                app.commands.execute 'addUnitsWithinBoundingBoxes', bboxes, level
    MapView
