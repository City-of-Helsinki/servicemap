define \
[
    'backbone'
], (
    Backbone
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
            if (@map.getZoom() == @map.getBoundsZoom(bounds) and
                @map.getBounds().contains bounds) then return

            if @opts.route.has 'plan'
                @map.fitBounds layer,
                    paddingTopLeft: [20,20]
                    paddingBottomRight: [20,20]

        centerLatLng: (latLng) ->
            if @map.getBounds().contains latLng
                return
            else
                @map.setView latLng

        adaptToLatLngs: (latLngs) ->
            switch latLngs.length
                when 0 then return
                when 1 then @centerLatLng latLngs[0]
                else @adaptToBounds L.latLngBounds latLngs

        _minimumUsefulWidenedView: ->

        zoomIn: ->
            @wasAutomatic = true
            @map.setZoom @map.getZoom() + 1
