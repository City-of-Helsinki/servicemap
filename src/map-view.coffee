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
    'app/map'
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
    map
) ->

    ICON_SIZE = 40
    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city

    class MapView extends MapBaseView
        tagName: 'div'
        initialize: (opts) ->
            super opts
            @units = opts.units
            @userClickCoordinatePosition = opts.userClickCoordinatePosition
            @selectedServices = opts.services
            @searchResults = opts.searchResults
            @selectedUnits = opts.selectedUnits
            #@listenTo @units, 'add', @drawUnits
            @selectedPosition = opts.selectedPosition
            @userPositionMarkers =
                accuracy: null
                position: null
                clicked: null

            @listenTo @units, 'finished', (options) =>
                # Triggered when all of the
                # pages of units have been fetched.
                @drawUnits @units
                if options?.refit
                    @refitBounds()

            @listenTo @userClickCoordinatePosition, 'change:value', (model, current) =>
                previous = model.previous?.value?()
                if previous?
                    @stopListening previous
                @map.off 'click'
                $('#map').css 'cursor', 'auto'
                @listenTo current, 'request', =>
                    $('#map').css 'cursor', 'crosshair'
                @map.on 'click', (e) =>
                    $('#map').css 'cursor', 'auto'
                    current.set 'location',
                        coordinates: [e.latlng.lng, e.latlng.lat]
                        accuracy: 0
                        type: 'Point'
                    current.set 'name', null
                    @handlePosition current

            @listenTo @units, 'unit:highlight', @highlightUnselectedUnit
            @listenTo @units, 'batch-remove', @removeUnits
            @listenTo @units, 'remove', @removeUnit
            @listenTo @units, 'reset', @renderUnits
            @listenTo @selectedUnits, 'reset', @handleSelectedUnit
            @listenTo p13n, 'position', @handlePosition
            @listenTo @selectedPosition, 'change:value', =>
                @handlePosition @selectedPosition.value(), center=true
            MapView.setMapActiveAreaMaxHeight
                maximize:
                    @selectedPosition.isEmpty() and @selectedUnits.isEmpty()
            $(window).resize => _.defer(_.bind(@recenter, @))

        renderUnits: (coll, opts) =>
            if @units.isEmpty()
                @clearPopups true
            unless opts?.retainMarkers then @allMarkers.clearLayers()
            markers = {}
            if @selectedUnits.isSet()
                marker = @markers[@selectedUnits.first().get('id')]
                if marker? then @markers = {id: marker}
            @units.each (unit) => @drawUnit(unit)
            if @selectedUnits.isSet()
                _.defer => @highlightSelectedUnit @selectedUnits.first()
            if not opts?.noRefit and not @units.isEmpty()
                @refitBounds()
            if @units.isEmpty() and opts?.bbox
                @showAllUnitsAtHighZoom()
            if @units.size() == 1
                @recenter()
            else if @units.isEmpty() and @selectedPosition.isEmpty()
                @setInitialView()

        drawUnits: (units) ->
            @allMarkers.clearLayers()
            @markers = {}
            unitsWithLocation = units.filter (unit) => unit.get('location')?
            markers = unitsWithLocation.map (unit) => @createMarker(unit)
            @allMarkers.addLayers markers

        handleSelectedUnit: (units, options) ->
            @clearPopups(true)
            if units.isEmpty()
                MapView.setMapActiveAreaMaxHeight maximize: true
                return
            unit = units.first()
            _.defer => @highlightSelectedUnit unit
            _.defer _.bind(@recenter, @)

        getMaxAutoZoom: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                7
            else if layer == 'ortographic'
                9
            else
                12

        handlePosition: (positionObject, center=false, opts) ->
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
            latLng = @latLngFromGeojson(positionObject)
            accuracyMarker = L.circle latLng, accuracy, weight: 0

            marker = map.MapUtils.createPositionMarker latLng, accuracy, positionObject.origin()
            marker.position = positionObject
            marker.on 'click', =>
                unless positionObject == @selectedPosition.value()
                    app.commands.execute 'selectPosition', positionObject
            marker.addTo @map

            @userPositionMarkers[key] = marker

            if isSelected
                @infoPopups.clearLayers()

            popup = @createPositionPopup positionObject, marker


            if @selectedUnits.isEmpty() and (
                @selectedPosition.isEmpty() or
                @selectedPosition.value() == positionObject or
                not positionObject?.isDetectedLocation())
                if opts?.initial
                    @infoPopups.addLayer popup
                else
                    @map.once 'moveend', =>
                        @infoPopups.addLayer popup


            positionObject.popup = popup

            if not opts?.skipRefit and (isSelected or center)
                if @map.getZoom() != @getZoomlevelToShowAllMarkers()
                    @map.setView latLng, @getZoomlevelToShowAllMarkers(),
                        animate: true
                else
                    @map.panTo latLng

        width: ->
            @$el.width()
        height: ->
            @$el.height()

        removeUnits: (options) ->
            @allMarkers.clearLayers()
            @markers = {}
            @drawUnits @units
            unless @selectedUnits.isEmpty()
                @highlightSelectedUnit @selectedUnits.first()
            if @units.isEmpty()
                @showAllUnitsAtHighZoom()

        removeUnit: (unit, units, options) ->
            if unit.marker?
                @allMarkers.removeLayer unit.marker
                delete unit.marker

        createClusterIcon: (cluster) ->
            count = cluster.getChildCount()
            serviceCollection = new models.ServiceList()
            markers = cluster.getAllChildMarkers()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                if @selectedServices.isEmpty()
                    service = new models.Service
                        id: marker.unit.get('root_services')[0]
                        root: marker.unit.get('root_services')[0]
                else
                    service = @selectedServices.find (s) =>
                        s.get('root') in marker.unit.get('root_services')
                serviceCollection.add service

            colors = serviceCollection.map (service) =>
                app.colorMatcher.serviceColor(service)

            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            new ctor count, ICON_SIZE, colors, serviceCollection.first().id

        createPositionPopup: (positionObject, marker) ->
            latLng = @latLngFromGeojson(positionObject)
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
            @clearPopups(true)
            popup = marker?.getPopup()
            unless popup
                return
            popup.selected = true
            popup.setLatLng marker.getLatLng()
            @popups.addLayer popup
            $(marker?._popup._wrapper).addClass 'selected'

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
                zoom: @getZoomlevelToShowAllMarkers()
                center: @latLngFromGeojson @selectedPosition.value()
            else if @selectedUnits.isSet()
                zoom: @getMaxAutoZoom()
                center: @latLngFromGeojson @selectedUnits.first()
            else
                # Default state without selections
                zoom: if (p13n.get('map_background_layer') == 'servicemap') then 10 else 5
                center: DEFAULT_CENTER

        getCenteredView: ->
            if @selectedPosition.isSet()
                center: @latLngFromGeojson @selectedPosition.value()
                zoom: @getZoomlevelToShowAllMarkers()
            else if @selectedUnits.isSet()
                center: @latLngFromGeojson @selectedUnits.first()
                zoom: Math.max @getMaxAutoZoom(), @map.getZoom()
            else
                null

        drawInitialState: =>
            if @selectedPosition.isSet()
                @showAllUnitsAtHighZoom()
                @handlePosition @selectedPosition.value(), center=false, skipRefit: true, initial: true
            else if @selectedUnits.isSet()
                @renderUnits @units, noRefit: true
            else if @units.isSet()
                @renderUnits @units

        resetMap: ->
            # With different projections the base layers cannot
            # be changed on a live map.
            window.location.reload true

        handleP13nChange: (path, newVal) ->
            if path[0] == 'map_background_layer'
                @resetMap()
            if path[0] != 'accessibility' or path[1] != 'colour_blind'
                return

            mapLayer = @makeBackgroundLayer()
            @map.addLayer mapLayer
            @map.removeLayer @backgroundLayer
            @backgroundLayer = mapLayer

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
            @_addMouseoverListeners @allMarkers
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

        _addMouseoverListeners: (markerClusterGroup)->
            markerClusterGroup.on 'clustermouseover', (e) =>
                @highlightUnselectedCluster e.layer
            markerClusterGroup.on 'mouseover', (e) =>
                @highlightUnselectedUnit e.layer.unit
            markerClusterGroup.on 'spiderfied', (e) =>
                icon = $(e.target._spiderfied?._icon)
                icon?.fadeTo('fast', 0)

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

    MapView
