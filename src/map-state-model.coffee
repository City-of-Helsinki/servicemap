define \
[
    'leaflet',
    'backbone',
    'app/map'
], (
    L,
    Backbone,
    MapUtils: MapUtils
) ->

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
                return

            if @opts.route?.has 'plan'
                # Transit plan fitting is the simplest case, handle it and return.
                if bounds?
                    @map.fitBounds bounds,
                        paddingTopLeft: [20,0]
                        paddingBottomRight: [20,20]
                return

            viewOptions =
                center: null
                zoom: null
                bounds: null
            zoom = Math.max MapUtils.getZoomlevelToShowAllMarkers(), @map.getZoom()
            if @opts.selectedUnits.isSet()
                viewOptions.center = MapUtils.latLngFromGeojson @opts.selectedUnits.first()
                viewOptions.zoom = zoom
            else if @opts.selectedPosition.isSet()
                viewOptions.center = MapUtils.latLngFromGeojson @opts.selectedPosition.value()
                radiusFilter = @opts.selectedPosition.value().get 'radiusFilter'
                if radiusFilter?
                    viewOptions.zoom = null
                    viewOptions.bounds = bounds
                else
                    viewOptions.zoom = zoom
            if @opts.selectedDivision.isSet()
                viewOptions = @_widenToDivision @opts.selectedDivision.value(), viewOptions
            if @opts.services.size() or @opts.searchResults.size() and @opts.selectedUnits.isEmpty()
                if bounds?
                    unless @opts.selectedPosition.isEmpty() and mapBounds.contains bounds
                        if @embedded == true
                            @map.fitBounds bounds
                            return
                        else
                            # Only zoom in, unless current map bounds is empty of units.
                            unitsInsideMap = @_objectsInsideBounds mapBounds, @opts.units
                            unless @opts.selectedPosition.isEmpty() and unitsInsideMap
                                viewOptions = @_widenViewMinimally @opts.units, viewOptions

            @setMapView viewOptions

        setMapView: (viewOptions) ->
            unless viewOptions?
                return
            bounds = viewOptions.bounds
            if bounds
                # Don't pan just to center the view if the bounds are already
                # contained, unless the map can be zoomed in.
                if (@map.getZoom() == @map.getBoundsZoom(bounds) and
                    @map.getBounds().contains bounds) then return
                @map.fitBounds viewOptions.bounds,
                    paddingTopLeft: [20, 0]
                    paddingBottomRight: [20, 20]
            else if viewOptions.center and viewOptions.zoom
                @map.setView viewOptions.center, viewOptions.zoom

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
            sortedUnits =
                units.chain()
                .filter (unit) => unit.has 'location'
                # TODO: profile?
                .sortBy (unit) => center.distanceTo MapUtils.latLngFromGeojson(unit)
                .value()

            topLatLngs = []
            unitsFound = {}
            if @opts.services.size()
                _.each @opts.services.pluck('id'), (id) =>
                    unitsFound[id] = UNIT_COUNT

                # We want to have at least UNIT_COUNT visible units
                # per service.
                for unit in sortedUnits
                    if _.isEmpty unitsFound
                        break
                    service = unit.collection.filters?.service
                    if service?
                        countLeft = unitsFound[service]
                        if countLeft?
                            unitsFound[service] -= 1
                            if unitsFound[service] == 0
                                delete unitsFound[service]
                        topLatLngs.push MapUtils.latLngFromGeojson(unit)
            # All of the search results have to be visible.
            else if @opts.searchResults.isSet()
                topLatLngs = _(sortedUnits).map (unit) =>
                    MapUtils.latLngFromGeojson(unit)
            if sortedUnits?.length
                viewOptions.bounds =
                    L.latLngBounds topLatLngs
                    .extend center
                viewOptions.center = null
                viewOptions.zoom = null

            viewOptions


        zoomIn: ->
            @wasAutomatic = true
            @map.setZoom @map.getZoom() + 1
