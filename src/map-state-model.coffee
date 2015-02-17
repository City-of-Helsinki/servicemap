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

            # Don't pan just to center if the bounds are already
            # contained.
            if (@map.getZoom() == @map.getBoundsZoom(bounds) and
                mapBounds.contains bounds) then return

            if @opts.route.has 'plan'
                @map.fitBounds bounds,
                    paddingTopLeft: [20,0]
                    paddingBottomRight: [20,20]

            else if @opts.services.size()
                unless mapBounds.contains bounds
                    unitsInsideMap = @_objectsInsideBounds mapBounds, @opts.units
                    # Only zoom in, unless current map bounds is empty of units.
                    if unitsInsideMap then return

                @_minimumUsefulWidenedView @opts.units

            else if @opts.selectedPosition.isSet()
                @centerLatLng

            else if @opts.selectedUnits.isSet()
                @centerLatLng MapUtils.latLngFromGeojson(@opts.selectedUnits.first())

        centerLatLng: (latLng, opts) ->
            zoom = @map.getZoom()
            if @opts.selectedPosition.isSet()
                zoom = MapUtils.getZoomlevelToShowAllMarkers()
            @map.setView latLng, zoom

        adaptToLatLngs: (latLngs) ->
            switch latLngs.length
                when 0 then return
                when 1 then @centerLatLng latLngs[0]
                else @adaptToBounds L.latLngBounds latLngs

        _objectsInsideBounds: (bounds, objects) ->
            objects.find (object) ->
                latLng = MapUtils.latLngFromGeojson (object)
                bounds.contains latLng

        _minimumUsefulWidenedView: (units) ->
            mapBounds = @map.getBounds()
            mapCenter = @map.getCenter()
            # TODO: profile?
            sortedUnits = units.sortBy (unit) =>
                mapCenter.distanceTo MapUtils.latLngFromGeojson(unit)
            if sortedUnits?.length
                newBounds = L.latLngBounds(mapBounds)
                    .extend MapUtils.latLngFromGeojson(sortedUnits[0])
                @map.fitBounds newBounds,
                    paddingTopLeft: [20,0]
                    paddingBottomRight: [20,20]

        zoomIn: ->
            @wasAutomatic = true
            @map.setZoom @map.getZoom() + 1
