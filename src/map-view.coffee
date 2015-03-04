define [
    'leaflet',
    'backbone',
    'backbone.marionette',
    'leaflet.markercluster',
    'leaflet.activearea',
    'i18next',
    'app/widgets',
    'app/models',
    'app/p13n',
    'app/jade',
    'app/map-base-view',
    'app/transit-map',
    'app/map',
    'app/base'
], (
    leaflet,
    Backbone,
    Marionette,
    markercluster,
    leaflet_activearea,
    i18n,
    widgets,
    models,
    p13n,
    jade,
    MapBaseView,
    TransitMapMixin,
    map,
    mixOf: mixOf
) ->

    ICON_SIZE = 40
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city

    class MapView extends mixOf MapBaseView, TransitMapMixin
        tagName: 'div'
        initialize: (@opts) ->
            super @opts
            @units = @opts.units
            @userClickCoordinatePosition = @opts.userClickCoordinatePosition
            @selectedServices = @opts.services
            @searchResults = @opts.searchResults
            @selectedUnits = @opts.selectedUnits
            #@listenTo @units, 'add', @drawUnits
            @selectedPosition = @opts.selectedPosition
            @userPositionMarkers =
                accuracy: null
                position: null
                clicked: null

            @listenTo @units, 'reset', @drawUnits
            @listenTo @units, 'finished', (options) =>
                # Triggered when all of the
                # pages of units have been fetched.
                @drawUnits @units, options

            @listenTo @selectedServices, 'add', (service, collection) =>
                if collection.size() == 1
                    @markers = {}
            @listenTo @selectedServices, 'remove', (model, collection) =>
                if collection.size() == 0
                    @markers = {}

            @listenTo @userClickCoordinatePosition, 'change:value', (model, current) =>
                previous = model.previous?.value?()
                if previous? then @stopListening previous
                @map.off 'click'
                $('#map').css 'cursor', 'auto'
                @listenTo current, 'request', =>
                    $('#map').css 'cursor', 'crosshair'
                    current.set 'preventPopup', true
                @map.on 'click', (e) =>
                    $('#map').css 'cursor', 'auto'
                    current.set 'location',
                        coordinates: [e.latlng.lng, e.latlng.lat]
                        accuracy: 0
                        type: 'Point'
                    current.set 'name', null
                    @handlePosition current, initial: true

            @listenTo @units, 'unit:highlight', @highlightUnselectedUnit
            @listenTo @units, 'batch-remove', @removeUnits
            @listenTo @units, 'remove', @removeUnit
            @listenTo @selectedUnits, 'reset', @handleSelectedUnit
            @listenTo p13n, 'position', @handlePosition
            @listenTo @selectedPosition, 'change:value', =>
                @handlePosition @selectedPosition.value(), center: true
            MapView.setMapActiveAreaMaxHeight
                maximize:
                    @selectedPosition.isEmpty() and @selectedUnits.isEmpty()

            @initializeTransitMap
                route: @opts.route
                selectedUnits: @selectedUnits
                selectedPosition: @selectedPosition

#            $(window).resize => _.defer(_.bind(@recenter, @))

        drawUnits: (units, options) ->
            if units.length == 0
                @allMarkers.clearLayers()
            unitsWithLocation = units.filter (unit) => unit.get('location')?
            markers = unitsWithLocation.map (unit) => @createMarker(unit, options?.marker)
            latLngs = _(markers).map (m) => m.getLatLng()
            unless options?.keepViewport
                @map.adaptToLatLngs latLngs
            @allMarkers.addLayers markers

        handleSelectedUnit: (units, options) ->
            if units.isEmpty()
                MapView.setMapActiveAreaMaxHeight maximize: true
                return
            unit = units.first()
            _.defer => @highlightSelectedUnit unit
#            _.defer _.bind(@recenter, @)

        getMaxAutoZoom: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                7
            else if layer == 'ortographic'
                9
            else
                12

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
            latLng = map.MapUtils.latLngFromGeojson positionObject
            accuracyMarker = L.circle latLng, accuracy, weight: 0

            marker = map.MapUtils.createPositionMarker latLng, accuracy, positionObject.origin()
            marker.position = positionObject
            marker.on 'click', =>
                app.commands.execute 'selectPosition', positionObject
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

            # if not opts?.skipRefit and (isSelected or opts?.center)
            #     if @map.getZoom() != @getZoomlevelToShowAllMarkers()
            #         @map.setView latLng, @getZoomlevelToShowAllMarkers(),
            #             animate: true
            #     else
            #         @map.panTo latLng

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
            name = positionObject.get('name') or i18n.t('map.retrieving_address')
            if positionObject == @selectedPosition.value()
                popupContents =
                    (ctx) =>
                        "<div class=\"unit-name\">#{ctx.name}</div>"
                offsetY = switch positionObject.origin()
                    when 'detected' then 10
                    when 'address' then 10
                    else 38
                popup = @createPopup L.point(0, offsetY)
                    .setContent popupContents
                        name: name
                    .setLatLng latLng
            else
                popupContents =
                    (ctx) =>
                        ctx.detected = positionObject?.isDetectedLocation()
                        $popupEl = $ jade.template 'position-popup', ctx
                        $popupEl.on 'click', (e) =>
                            @infoPopups.clearLayers()
                            unless positionObject == @selectedPosition.value()
                                e.stopPropagation()
                                @map.removeLayer positionObject.popup
                                app.commands.execute 'selectPosition', positionObject
                                marker.closePopup()
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
                        name: name

            posList = models.PositionList.fromPosition positionObject
            @listenTo posList, 'sync', =>
                bestMatch = posList.first()
                if bestMatch.get('distance') > 500
                    bestMatch.set 'name', i18n.t 'map.unknown_address'
                positionObject.set bestMatch.toJSON()
                popup.setContent popupContents
                    name: bestMatch.get 'name'
                positionObject.trigger 'reverse_geocode'

            popup

        highlightSelectedUnit: (unit) ->
            # Prominently highlight the marker whose details are being
            # examined by the user.
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
                $(marker?._icon).removeClass 'selected'
                $(marker?.popup._wrapper).removeClass 'selected'
                @popups.removeLayer marker?.popup
            $(marker?._icon).addClass 'selected'
            $(marker?.popup._wrapper).addClass 'selected'

        selectMarker: (event) ->
            marker = event.target
            unit = marker.unit
            app.commands.execute 'selectUnit', unit

        drawUnit: (unit, units, options) ->
            location = unit.get('location')
            if location?
                marker = @createMarker unit
                @allMarkers.addLayer marker


        calculateInitialOptions: ->
            if @selectedPosition.isSet()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
            else if @selectedUnits.isSet()
                zoom: @getMaxAutoZoom()
                center: map.MapUtils.latLngFromGeojson @selectedUnits.first()
            else
                # Default state without selections
                zoom: if (p13n.get('map_background_layer') == 'servicemap') then 10 else 5
                center: DEFAULT_CENTER

        getCenteredView: ->
            if @selectedPosition.isSet()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
            else if @selectedUnits.isSet()
                center: map.MapUtils.latLngFromGeojson @selectedUnits.first()
                zoom: Math.max @getMaxAutoZoom(), @map.getZoom()
            else
                null

        drawInitialState: =>
            if @selectedPosition.isSet()
                @showAllUnitsAtHighZoom()
                @handlePosition @selectedPosition.value(),
                    center: false,
                    skipRefit: true,
                    initial: true
            else if @selectedUnits.isSet()
                @drawUnits @units, noRefit: true
            else if @units.isSet()
                @drawUnits @units

        resetMap: ->
            # With different projections the base layers cannot
            # be changed on a live map.
            window.location.reload true

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

        addMapActiveArea: ->
            @map.setActiveArea 'active-area'
            MapView.setMapActiveAreaMaxHeight
                maximize: @selectedUnits.isEmpty() and @selectedPosition.isEmpty()

        setInitialView: ->
            opts = @calculateInitialOptions()
            @map.setView opts.center, opts.zoom

        initializeMap: ->
            @setInitialView()
            window.debugMap = map
            @listenTo p13n, 'change', @handleP13nChange
            # The line below is for debugging without clusters.
            # @allMarkers = L.featureGroup()
            @popups = L.layerGroup()
            @infoPopups = L.layerGroup()

            L.control.scale(imperial: false).addTo(@map);

            L.control.zoom(
                position: 'bottomright'
                zoomInText: '<span class="icon-icon-zoom-in"></span>'
                zoomOutText: '<span class="icon-icon-zoom-out"></span>').addTo @map
            @popups.addTo @map
            @infoPopups.addTo @map

            @debugGrid = L.layerGroup().addTo(@map)
            @debugCircles = {}

            @map.on 'zoomstart', =>
                toRemove = _.filter @markers, (m) =>
                    unit = m?.unit
                    unit?.collection?.filters?.bbox? and not unit?.get 'selected'
                @allMarkers.removeLayers toRemove
                @_clearOtherPopups null, null
            @map.on 'moveend', =>
                # TODO: cleaner way to prevent firing from refit
                if @skipMoveend
                    @skipMoveend = false
                    return
                @showAllUnitsAtHighZoom()

            # If the user has allowed location requests before,
            # try to get the initial location now.
            if p13n.getLocationRequested()
                p13n.requestLocation()

            @userClickCoordinatePosition.wrap new models.CoordinatePosition
                isDetected: false

            @previousZoomlevel = @map.getZoom()
            @drawInitialState()

        postInitialize: ->
            @addMapActiveArea()
            @initializeMap()
            @_addMouseoverListeners @allMarkers

        @mapActiveAreaMaxHeight: =>
            screenWidth = $(window).innerWidth()
            screenHeight = $(window).innerHeight()
            Math.min(screenWidth * 0.4, screenHeight * 0.3)

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
            zoom = @map.getZoom()
            if zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()
                if (@selectedUnits.isSet() and @map.getBounds().contains @selectedUnits.first().marker.getLatLng())
                    # Don't flood a selected unit's surroundings
                    return
                if @selectedServices.isSet()
                    return
                if @searchResults.isSet()
                    return
                transformedBounds = map.MapUtils.overlappingBoundingBoxes @map
                bboxes = []
                for bbox in transformedBounds
                    bboxes.push "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
                app.commands.execute 'addUnitsWithinBoundingBoxes', bboxes
            else
                app.commands.execute 'clearUnits', all: false, bbox: true, silent: true
    MapView
