define "app/widgets", ['app/draw', 'leaflet', 'servicetree', 'underscore', 'jquery', 'backbone', 'app/jade'], (draw, leaflet, service_tree, _, $, Backbone, jade) ->

    CanvasIcon = L.Icon.extend
        initialize: (@dimension, @color) ->
            @options.iconSize = new L.Point @dimension, @dimension
            @options.iconAnchor = new L.Point @options.iconSize.x/2, @options.iconSize.y
            @plant = new draw.Plant(@dimension, @color)
        options:
            className: 'leaflet-canvas-icon'
        createIcon: ->
            el = document.createElement 'canvas'
            # If the IE Canvas polyfill is installed, the element needs to be specially
            # initialized.
            if G_vmlCanvasManager?
                G_vmlCanvasManager.initElement el
            @_setIconStyles el, 'icon'
            s = @options.iconSize
            el.width = s.x + 20
            el.height = s.y + 20
            @plant.draw el.getContext('2d')
            return el
        createShadow: ->
            return null

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
        LeftAlignedPopup: LeftAlignedPopup
    exports

