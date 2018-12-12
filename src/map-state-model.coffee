define (require) ->
    L          = require 'leaflet'
    Backbone   = require 'backbone'

    {MapUtils} = require 'cs!app/map'

    VIEWPOINTS =
        # meters to show everything within in every direction
        singleUnitImmediateVicinity: 200
        singleObjectEmbedded: 400

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

    class MapStateModel extends Backbone.Model
        # Models map center, bounds and zoom in a unified way.
        initialize: (@opts, @embedded) ->
            @userHasModifiedView = false
            @wasAutomatic = false
            @zoom = null
            @bounds = null
            @center = null

            @listenTo @opts.selectedPosition, 'change:value', @onSelectPosition

        setMap: (@map) ->
            @map.mapState = @
            @map.on 'moveend', _.bind(@onMoveEnd, @)

        onSelectPosition: (position) =>
            if position.isSet() then @setUserModified()

        onMoveEnd: ->
            unless @wasAutomatic
                @setUserModified()
            @wasAutomatic = false

        setUserModified: ->
            @userHasModifiedView = true

        adaptToLayer: (layer) ->
            @adaptToBounds layer.getBounds()

        adaptToBounds: (bounds) ->
            mapBounds = @map.getBounds()
            # Don't pan just to center the view if the bounds are already
            # contained, unless the map can be zoomed in.
            if bounds? and (@map.getZoom() == @map.getBoundsZoom(bounds) and mapBounds.contains bounds)
                return false

            if @opts.route?.has 'plan'
                # Transit plan fitting is the simplest case, handle it and return.
                if bounds?
                    @map.fitBounds bounds,
                        paddingTopLeft: [20,0]
                        paddingBottomRight: [20,20]
                return false

            viewOptions =
                center: null
                zoom: null
                bounds: null
            zoom = Math.max MapUtils.getZoomlevelToShowAllMarkers(), @map.getZoom()
            EMBED_RADIUS = VIEWPOINTS['singleObjectEmbedded']

            if @opts.selectedUnits.isSet()
                if @embedded == true
                    viewOptions.zoom = null
                    viewOptions.bounds = boundsFromRadius EMBED_RADIUS,
                        MapUtils.latLngFromGeojson(@opts.selectedUnits.first())
                else
                    viewOptions.center = MapUtils.latLngFromGeojson @opts.selectedUnits.first()
                    viewOptions.zoom = zoom

                    # When a popup is open for the currently selected unit,
                    # centering the view will move the popup out of view on mobile screens.
                    # Only change the latitude in this case.
                    if $(window).innerWidth() <= appSettings.mobile_ui_breakpoint and
                            @opts.selectedUnits.first().marker?.getPopup()
                        viewOptions.center.lng = @map.getCenter().lng
            else if @opts.selectedPosition.isSet()
                if @embedded == true
                    viewOptions.zoom = null
                    viewOptions.bounds = boundsFromRadius EMBED_RADIUS,
                        MapUtils.latLngFromGeojson(@opts.selectedPosition.value())
                else
                    viewOptions.center = MapUtils.latLngFromGeojson @opts.selectedPosition.value()
                    radiusFilter = @opts.selectedPosition.value().get 'radiusFilter'

                    if radiusFilter?
                        viewOptions.zoom = null
                        viewOptions.bounds = bounds
                    else
                        viewOptions.zoom = zoom

            if @opts.selectedDivision.isSet()
                viewOptions = @_widenToDivision @opts.selectedDivision.value(), viewOptions

            if bounds? and (
                    @opts.selectedServiceNodes.size() or
                    @opts.selectedServices.size() or
                    @opts.searchResults.size() and @opts.selectedUnits.isEmpty())
                if @embedded == true
                    @map.fitBounds bounds
                    return true

                unless @opts.selectedPosition.isEmpty() and mapBounds.contains bounds
                    # Only zoom in, unless current map bounds is empty of units.
                    unitsInsideMap = @_objectsInsideBounds mapBounds, @opts.units
                    unless @opts.selectedPosition.isEmpty() and unitsInsideMap
                        viewOptions = @_widenViewMinimally @opts.units, viewOptions

            @setMapView viewOptions

        setMapView: (viewOptions) ->
            unless viewOptions?
                return false
            bounds = viewOptions.bounds
            if bounds
                # Don't pan just to center the view if the bounds are already
                # contained, unless the map can be zoomed in.
                if (@map.getZoom() == @map.getBoundsZoom(bounds) and
                    @map.getBounds().contains bounds) then return
                @map.fitBounds viewOptions.bounds,
                    paddingTopLeft: [20, 0]
                    paddingBottomRight: [20, 20]
                return true
            else if viewOptions.center and viewOptions.zoom
                @map.setView viewOptions.center, viewOptions.zoom
                return true

        centerLatLng: (latLng, opts) ->
            zoom = @map.getZoom()
            if @opts.selectedPosition.isSet()
                zoom = MapUtils.getZoomlevelToShowAllMarkers()
            else if @opts.selectedUnits.isSet()
                zoom = MapUtils.getZoomlevelToShowAllMarkers()
            @map.setView latLng, zoom

        adaptToLatLngs: (latLngs) ->
            if latLngs.length == 0
                return
            @adaptToBounds L.latLngBounds latLngs

        _objectsInsideBounds: (bounds, objects) ->
            objects.find (object) ->
                latLng = MapUtils.latLngFromGeojson (object)
                if latLng?
                    return bounds.contains latLng
                false

        _widenToDivision: (division, viewOptions) ->
            mapBounds = @map.getBounds()
            viewOptions.center = null
            viewOptions.zoom = null
            bounds = L.latLngBounds L.GeoJSON.geometryToLayer(division.get('boundary'), null, null, {}).getBounds()
            if mapBounds.contains bounds
                viewOptions = null
            else
                viewOptions.bounds = bounds
            viewOptions

        _widenViewMinimally: (units, viewOptions) ->
            UNIT_COUNT = 2
            mapBounds = @map.getBounds()
            center = viewOptions.center or @map.getCenter()
            sortedUnits = units.chain()
                .filter (unit) => unit.has 'location'
                # TODO: profile?
                .sortBy (unit) => center.distanceTo MapUtils.latLngFromGeojson(unit)
                .value()

            topLatLngs = []

            if @opts.selectedServiceNodes.size() or @opts.selectedServices.size()
                topLatLngs = @_getCoordinatesForServiceUnits UNIT_COUNT, sortedUnits
            else if @opts.searchResults.isSet()
                # All of the search results have to be visible.
                topLatLngs = _(sortedUnits).map (unit) =>
                    MapUtils.latLngFromGeojson(unit)

            if sortedUnits?.length
                viewOptions.bounds =
                    L.latLngBounds topLatLngs
                    .extend center
                viewOptions.center = null
                viewOptions.zoom = null

            viewOptions

        zoomTo: (level) ->
            @map.setZoom level, animate: true

        # Get coordinates for at least atLeastCount units per service.
        _getCoordinatesForServiceUnits: (atLeastCount, sortedUnits) ->
            latLngs = []

            serviceUnitsFound = {}
            serviceNodeUnitsFound = {}

            _.each @opts.selectedServices.pluck('id'), (id) =>
                serviceUnitsFound[id] = atLeastCount
            _.each @opts.selectedServiceNodes.pluck('id'), (id) =>
                serviceNodeUnitsFound[id] = atLeastCount

            decreaseCount = (id, unitsFound) ->
                if unitsFound[id]?
                    unitsFound[id] -= 1
                    if unitsFound[id] < 1
                        delete unitsFound[id]

            for unit in sortedUnits
                if _.isEmpty(serviceUnitsFound) and _.isEmpty(serviceNodeUnitsFound)
                    break

                serviceId = unit.collection.filters?.service
                if serviceId?
                    decreaseCount serviceId, serviceUnitsFound
                    latLngs.push MapUtils.latLngFromGeojson(unit)

                serviceNodeId = unit.collection.filters?.service_node
                if serviceNodeId?
                    decreaseCount serviceNodeId, serviceNodeUnitsFound
                    latLngs.push MapUtils.latLngFromGeojson(unit)

            return latLngs
