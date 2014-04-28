define "app/widgets", ['app/draw', 'leaflet', 'servicetree', 'underscore', 'jquery', 'backbone'], (draw, leaflet, service_tree, _, $, Backbone) ->


    TitleControl: L.Control.extend
        options:
            position: 'bottomright'
        onAdd: (map) ->
            # create the control container with a particular class name
            container = L.DomUtil.create 'div', 'title-control'
            $logo = $('<img class="logo" src="images/service-map-logo.png" alt="Service Map logo">')
            $(container).append $logo
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

    ServiceSidebarControl: L.Control.extend
        initialize: (@element, options) ->
            L.Util.setOptions this, options
        options:
            position: 'topleft'
        onAdd: (map) ->
            @element

    CanvasIcon: L.Icon.extend
        initialize: (@dimension, @color) ->
            @options.iconSize = new L.Point @dimension, @dimension
            @options.iconAnchor = new L.Point @options.iconSize.x/2, @options.iconSize.y
            @plant = new draw.Plant(@dimension, @color)
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
