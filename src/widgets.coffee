define "app/widgets", ['leaflet', 'servicetree', 'underscore', 'jquery', 'backbone'], (leaflet, service_tree, _, $, Backbone) ->


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
            @options.iconSize = new L.Point 11*@dimension/25,@dimension
            @options.iconAnchor = new L.Point @options.iconSize.x/2, @options.iconSize.y
        options:
            className: 'leaflet-canvas-icon'
            color: "#000"
        createIcon: ->
            el = document.createElement 'canvas'
            this._setIconStyles el, 'icon'
            s = @options.iconSize
            el.width = s.x
            el.height = s.y
            @draw(el.getContext('2d'), s.x, s.y)
            return el
        createShadow: ->
            return null
        draw: (ctx, w, h) ->
            #ctx.globalAlpha = 0.5
            ctx.lineCap = 'round'
            ctx.lineWidth = 4*w/30
            ctx.strokeStyle = "#221"
            ctx.beginPath()
            ctx.moveTo w/2, h-4
            ctx.bezierCurveTo 2*w/3, h/3, (12/20)*w, h/4, w/3, h/6
            ctx.stroke()
            ctx.closePath()

            berryWidth = h/5

            ctx.beginPath()
            ctx.translate w/2, h/5
            ctx.lineWidth = 4
            ctx.strokeStyle = 'rgba(0,0,0,1.0)'
            ctx.fillStyle = @options.color
            ctx.arc 0, 0, berryWidth, 0, Math.PI*2, true
            ctx.fill()
            old_composite = ctx.globalCompositeOperation
            ctx.globalCompositeOperation = "destination-out"
            ctx.stroke()
            ctx.globalCompositeOperation = old_composite
            ctx.closePath()
