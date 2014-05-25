define "app/widgets", ['app/draw', 'leaflet', 'servicetree', 'underscore', 'jquery', 'backbone', 'app/jade'], (draw, leaflet, service_tree, _, $, Backbone, jade) ->

    CanvasIcon: L.Icon.extend
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
