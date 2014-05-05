define "app/widgets", ['app/draw', 'leaflet', 'servicetree', 'underscore', 'jquery', 'backbone', 'app/jade'], (draw, leaflet, service_tree, _, $, Backbone, jade) ->
    class LandingTitleView extends Backbone.View
        initialize: ->
            @listenTo(app.vent, 'title-view:hide', @hideTitleView)
            @listenTo(app.vent, 'title-view:show', @unHideTitleView)
        render: =>
            @el.innerHTML = jade.template 'landing-title-view', isHidden: @isHidden

        hideTitleView: ->
            $('body').removeClass 'landing'
            @isHidden = true
            @render()

        unHideTitleView: ->
            $('body').addClass 'landing'
            @isHidden = false
            @render()


    LandingTitleView: LandingTitleView

    TitleControl: L.Control.extend
        options:
            position: 'bottomright'
        onAdd: (map) ->
            # create the control container with a particular class name
            container = L.DomUtil.create 'div', 'title-control'
            $logo = $('<img class="logo" src="images/service-map-logo.png" alt="Service Map logo">')
            $(container).append $logo
            return container

    LandingTitleControl: L.Control.extend
        options:
            position: 'topleft'
        onAdd: (map) ->
            # create the control container with a particular class name
            container = L.DomUtil.create 'div', 'landing-title-control'
            return container

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
