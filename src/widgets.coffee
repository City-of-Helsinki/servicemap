define "app/widgets", ['app/draw', 'leaflet', 'underscore', 'jquery', 'backbone', 'app/jade'], (draw, leaflet, _, $, Backbone, jade) ->

    anchor = (size) ->
        x = size.x/3 + 5
        y = size.y/2 + 16
        new L.Point x, y

    CanvasIcon = L.Icon.extend
        initialize: (@dimension) ->
            @options.iconSize = new L.Point (Math.ceil(@dimension * 0.45) + 2), (@dimension + 2)
            @options.iconAnchor = @iconAnchor()
        options:
            className: 'leaflet-canvas-icon'
        setupCanvas: ->
            if @el?
                el = @el
            else
                el = document.createElement 'canvas'
                # If the IE Canvas polyfill is installed, the element needs to be specially
                # initialized.
                if G_vmlCanvasManager?
                    G_vmlCanvasManager.initElement el
                @_setIconStyles el, 'icon'
            s = @getSize()
            el.width = s.x
            el.height = s.y
            el.style.width = "#{s.x}px"
            el.style.height = "#{s.y}px"
            el
        getSize: ->
            @options.iconSize
        # reDraw: (zoomLevel) ->
        #     # 15 - 8
        #     @dimension *= (100 * (zoomLevel - 8) / 7)
        #     @createIcon()
        createIcon: ->
            @el = @setupCanvas()
            @draw @el.getContext('2d')
            @el
        createShadow: ->
            return null
        iconAnchor: ->
            anchor @options.iconSize

    PlantCanvasIcon = CanvasIcon.extend
        initialize: (@dimension, @color, id) ->
            @plant = new draw.Plant @dimension, @color, id
            CanvasIcon.prototype.initialize.call this, @dimension
        iconAnchor: ->
            [x, y] = @plant.get_anchor()
            x += 1 # 1 pixel margin
            y += 1
            new L.Point x, y
        draw: (ctx) ->
            console.log 'plantcanvasicon draw'
            @plant.draw ctx
        getSize: ->
            x = Math.ceil @plant.get_width()
            y = @dimension + 2
            @options.iconSize = new L.Point x, y
            x: x
            y: y

    PointCanvasIcon = CanvasIcon.extend
        initialize: (@dimension, @color, id) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @drawer = new draw.PointPlant @dimension, @color, 2
        draw: (ctx) ->
            @drawer.draw ctx

    CanvasClusterIcon = CanvasIcon.extend
        initialize: (@count, @dimension, @colors, id) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @options.iconSize = new L.Point @dimension + 20, @dimension + 10
            if @count > 5
                @count = 5
            rotations = [130,110,90,70,50]
            translations = [[0,5],[10, 7],[12,8],[15,10],[5, 12]]
            @plants = _.map [1..@count], (i) =>
                new draw.Plant(@dimension, @colors[(i-1) % @colors.length],
                    id, rotations[i-1], translations[i-1],
                    cluster=true)
        draw: (ctx) ->
            console.log 'canvasclustericon draw'
            for plant in @plants
                plant.draw ctx

    PointCanvasClusterIcon = CanvasIcon.extend
        initialize: (count, @dimension, @colors, id) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @count = (Math.min(20, count) / 5) * 5
            @radius = 2
            range = =>
                @radius + Math.random() * (@dimension - 2 * @radius)
            @positions = _.map [1..@count], (i) =>
                [range(), range()]
            @cluster_drawer = new draw.PointCluster @dimension, @colors, @positions, @radius
        draw: (ctx) ->
            @setupCanvas()
            @cluster_drawer.draw ctx

    LeftAlignedPopup = L.Popup.extend
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

    exports =
        CanvasIcon: CanvasIcon
        PlantCanvasIcon: PlantCanvasIcon
        PointCanvasIcon: PointCanvasIcon
        CanvasClusterIcon: CanvasClusterIcon
        PointCanvasClusterIcon: PointCanvasClusterIcon
        LeftAlignedPopup: LeftAlignedPopup
    exports
