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
        initialize: (@opts) ->
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
            if bounds? and (@map.getZoom() == @map.getBoundsZoom(bounds) and
                mapBounds.contains bounds) then return

            if @opts.route.has 'plan'
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
                viewOptions.zoom = zoom

            if @opts.services.size() and @opts.selectedUnits.isEmpty()
                if bounds?
                    unless @opts.selectedPosition.isEmpty() and mapBounds.contains bounds
                        # Only zoom in, unless current map bounds is empty of units.
                        unitsInsideMap = @_objectsInsideBounds mapBounds, @opts.units
                        unless @opts.selectedPosition.isEmpty() and unitsInsideMap
                            viewOptions = @_widenViewMinimally @opts.units, viewOptions

            else if @opts.searchResults.size()
                if bounds?
                    # Always zoom in to fit bounds, otherwise if there are no
                    # visible results inside the viewport, fit bounds.
                    if @_objectsInsideBounds mapBounds, @opts.units
                        unless @map.getZoom() >= @map.getBoundsZoom(bounds)
                            viewOptions.bounds = bounds

            @setMapView viewOptions

        setMapView: (viewOptions) ->
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

        _widenViewMinimally: (units, viewOptions) ->
            mapBounds = @map.getBounds()
            center = viewOptions.center or @map.getCenter()
            # TODO: profile?
            sortedUnits =
                units.chain()
                .filter (unit) => unit.has 'location'
                .sortBy (unit) => center.distanceTo MapUtils.latLngFromGeojson(unit)
                .value()

            topThreeLatLngs =
                _(sortedUnits.slice 0, 2)
                .map (unit) =>
                    MapUtils.latLngFromGeojson unit

            if sortedUnits?.length
                viewOptions.bounds =
                    L.latLngBounds topThreeLatLngs
                    .extend center
                viewOptions.center = null
                viewOptions.zoom = null

            viewOptions


        zoomIn: ->
            @wasAutomatic = true
            @map.setZoom @map.getZoom() + 1
