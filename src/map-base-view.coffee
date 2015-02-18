define [
    'backbone',
    'backbone.marionette',
    'i18next',
    'leaflet',
    'leaflet.markercluster',
    'app/map',
    'app/widgets',
    'app/jade',
    'app/map-state-model',
], (
    Backbone,
    Marionette,
    i18n,
    leaflet,
    markercluster,
    map,
    widgets,
    jade,
    MapStateModel
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
        initialize: (opts) ->
            @markers = {}

        zoomlevelSinglePoint: (latLng, viewpoint) ->
            bounds = boundsFromRadius VIEWPOINTS[viewpoint], latLng
            @map.getBoundsZoom bounds

        mapOptions: {}

        render: ->
            @$el.attr 'id', 'map'

        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            mapStyle = p13n.get 'map_background_layer'
            options =
                style: mapStyle
                language: p13n.getLanguage()
            @map = map.MapMaker.createMap @$el.get(0), options, @mapOptions, new MapStateModel @opts
            @allMarkers = @getFeatureGroup()
            @allMarkers.addTo @map
            @postInitialize()

        postInitialize: ->
            @_addMouseoverListeners @allMarkers
            @popups = L.layerGroup()
            @popups.addTo @map

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
            serviceCollection = new models.ServiceList()
            markers = cluster.getAllChildMarkers()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                if marker.popup?
                    cluster.on 'remove', (event) =>
                        @popups.removeLayer marker.popup
                services = @getServices()
                if not services or services.isEmpty()
                    service = new models.Service
                        id: marker.unit.get('root_services')[0]
                        root: marker.unit.get('root_services')[0]
                else
                    service = services.find (s) =>
                        s.get('root') in marker.unit.get('root_services')
                serviceCollection.add service
            cluster.on 'remove', (event) =>
                if cluster.popup?
                    @popups.removeLayer cluster.popup
            colors = serviceCollection.map (service) =>
                app.colorMatcher.serviceColor(service)

            reducedProminence = _(markers).find((m) => m.options?.reducedProminence)?
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            new ctor count, ICON_SIZE, colors, serviceCollection.first().id,
                reducedProminence: reducedProminence

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
                return @markers[id]
            icon = @createIcon unit, @selectedServices,
                reducedProminence: markerOptions?.reducedProminence
            marker = L.marker map.MapUtils.latLngFromGeojson(unit),
                icon: icon
                zIndexOffset: 100
                reducedProminence: markerOptions?.reducedProminence
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
                if opts.clearSelected or not layer.selected
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
                if _popup? and not _popup.selected
                    @popups.removeLayer _popup
                prevent = true
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

        createIcon: (unit, services, iconOptions) ->
            color = app.colorMatcher.unitColor(unit) or 'rgb(255, 255, 255)'
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasIcon
            else
                ctor = widgets.PlantCanvasIcon
            icon = new ctor ICON_SIZE, color, unit.id, iconOptions

        showAllUnitsAtHighZoom: ->
            if $(window).innerWidth() <= appSettings.mobile_ui_breakpoint
                return
            zoom = @map.getZoom()
            if zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()
                if (@selectedUnits.isSet() and @map.getBounds().contains(@selectedUnits.first().marker.getLatLng()))
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
                app.commands.execute 'clearUnits', all: false, bbox: true

    return MapBaseView
