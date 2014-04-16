define "app/widgets", ['app/draw', 'leaflet', 'servicetree', 'underscore', 'jquery', 'backbone'], (draw, leaflet, service_tree, _, $, Backbone) ->


    TitleControl: L.Control.extend
        options:
            position: 'topleft'
        onAdd: (map) ->
            # create the control container with a particular class name
            container = L.DomUtil.create 'div', 'title-control'
            logo = L.DomUtil.create 'h2', 'title-logo', container
            logo.innerHTML = '[LOGO] Service Map'
            return container

    SearchControl: L.Control.extend
        options:
            position: 'topright'
        onAdd: (map) ->
            $container = $("<div id='search' />")
            $el = $("<input type='text' name='query' class='form-control'>")
            $el.css
                width: '250px'
            $container.append $el
            return $container.get(0)

    ServiceTreeControl: L.Control.extend
        initialize: (@element, options) ->
            L.Util.setOptions this, options
        options:
            position: 'topleft'
        onAdd: (map) ->
            @element

    CanvasIcon: L.Icon.extend
        initialize: (@dimension) ->
            @options.iconSize = new L.Point @dimension, @dimension
            @options.iconAnchor = new L.Point @options.iconSize.x/2, @options.iconSize.y
            @plant = new draw.Plant(@dimension)
        options:
            className: 'leaflet-canvas-icon'
        createIcon: ->
            el = document.createElement 'canvas'
            this._setIconStyles el, 'icon'
            s = @options.iconSize
            el.width = s.x + 20
            el.height = s.y + 20
            @plant.draw(el.getContext('2d'))
            return el
        createShadow: ->
            return null
