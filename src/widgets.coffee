define [
    'app/draw',
    'leaflet',
    'leaflet.markercluster',
    'underscore',
    'jquery',
    'backbone',
    'app/jade'
], (
    draw,
    leaflet,
    markercluster,
    _,
    $,
    Backbone,
    jade
) ->

    anchor = (size) ->
        x = size.x/3 + 5
        y = size.y/2 + 16
        new L.Point x, y

    REDUCED_OPACITY = 0.5

    # BEGIN hack to enable transparent markers
    OriginalMarkerCluster = L.MarkerCluster
    SMMarkerCluster = L.MarkerCluster.extend
        setOpacity: (opacity) ->
            children = @getAllChildMarkers()
            reducedProminence = false
            if children.length
                reducedProminence = children[0].unit?.collection?.filters?.bbox?
            if reducedProminence and opacity == 1
                opacity = REDUCED_OPACITY
            OriginalMarkerCluster::setOpacity.call @, opacity
    L.MarkerCluster = SMMarkerCluster

    SMMarker = L.Marker.extend
        setOpacity: (opacity) ->
            if @options.reducedProminence and opacity == 1
                opacity = REDUCED_OPACITY
            L.Marker::setOpacity.call @, opacity
    # END hack

    CanvasIcon = L.Icon.extend
        initialize: (@dimension, options) ->
            @options.iconSize = new L.Point @dimension, @dimension
            @options.iconAnchor = @iconAnchor()
            @options.reducedProminence = options.reducedProminence
        options:
            className: 'leaflet-canvas-icon'
        setupCanvas: ->
            el = document.createElement 'canvas'
            # If the IE Canvas polyfill is installed, the element needs to be specially
            # initialized.
            if G_vmlCanvasManager?
                G_vmlCanvasManager.initElement el
            @_setIconStyles el, 'icon'
            s = @options.iconSize
            el.width = s.x
            el.height = s.y
            if @options.reducedProminence
                L.DomUtil.setOpacity el, REDUCED_OPACITY
            el
        createIcon: ->
            el = @setupCanvas()
            @draw el.getContext('2d')
            el
        createShadow: ->
            return null
        iconAnchor: ->
            anchor @options.iconSize

    PlantCanvasIcon: CanvasIcon.extend
        initialize: (@dimension, @color, id, options) ->
            CanvasIcon.prototype.initialize.call this, @dimension, options
            @plant = new draw.Plant @dimension, @color, id
        draw: (ctx) ->
            @plant.draw ctx

    PointCanvasIcon: CanvasIcon.extend
        initialize: (@dimension, @color, id) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @drawer = new draw.PointPlant @dimension, @color, 2
        draw: (ctx) ->
            @drawer.draw ctx

    CanvasClusterIcon: CanvasIcon.extend
        initialize: (@count, @dimension, @colors, id, options) ->
            CanvasIcon.prototype.initialize.call this, @dimension, options
            @options.iconSize = new L.Point @dimension + 30, @dimension + 30
            if @count > 5
                @count = 5
            rotations = [130,110,90,70,50]
            translations = [[0,5],[10, 7],[12,8],[15,10],[5, 12]]
            @plants = _.map [1..@count], (i) =>
                new draw.Plant(@dimension, @colors[(i-1) % @colors.length],
                    id, rotations[i-1], translations[i-1])
        draw: (ctx) ->
            for plant in @plants
                plant.draw ctx

    PointCanvasClusterIcon: CanvasIcon.extend
        initialize: (count, @dimension, @colors, id) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @count = (Math.min(20, count) / 5) * 5
            @radius = 2
            range = =>
                @radius + Math.random() * (@dimension - 2 * @radius)
            @positions = _.map [1..@count], (i) =>
                [range(), range()]
            @clusterDrawer = new draw.PointCluster @dimension, @colors, @positions, @radius
        draw: (ctx) ->
            @clusterDrawer.draw ctx

    LeftAlignedPopup: L.Popup.extend
        _updatePosition: ->
            if !this._map
                return

            pos = this._map.latLngToLayerPoint(this._latlng)
            animated = this._animated
            offset = L.point(this.options.offset)

            properOffset =
                x: 15
                y: -27

            if animated
                pos.y = pos.y + properOffset.y
                pos.x = pos.x + properOffset.x
                L.DomUtil.setPosition(this._container, pos);

            this._containerBottom = -offset.y - (if animated then 0 else pos.y + properOffset.y)
            this._containerLeft = offset.x + (if animated then 0 else pos.x + properOffset.x)

            # bottom position the popup in case the height of the popup changes (images loading etc)
            this._container.style.bottom = this._containerBottom + 'px';
            this._container.style.left = this._containerLeft + 'px';

    SMMarker: SMMarker
    SMMarkerCluster: SMMarkerCluster
