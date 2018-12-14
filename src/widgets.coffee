define (require) ->
    leaflet                     = require 'leaflet'
    markercluster               = require 'leaflet.markercluster'
    _                           = require 'underscore'
    $                           = require 'jquery'
    Backbone                    = require 'backbone'

    draw                        = require 'cs!app/draw'
    jade                        = require 'cs!app/jade'
    {typeToName, vehicleTypes}  = require 'cs!app/transit'

    anchor = (size) ->
        x = size.x/3 + 5
        y = size.y/2 + 16
        new L.Point x, y

    SMMarker = L.Marker
    REDUCED_OPACITY = 1

    initializer = ->
        # BEGIN hack to enable transparent markers
        REDUCED_OPACITY = 0.5
        OriginalMarkerCluster = L.MarkerCluster
        SMMarkerCluster = L.MarkerCluster.extend
            setOpacity: (opacity) ->
                children = @getAllChildMarkers()
                reducedProminence = false
                if children.length
                    reducedProminence = children[0].unit?.collection?.hasReducedPriority()
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
    createMarker = (args...) ->
        new SMMarker args...

    CanvasIcon = L.Icon.extend
        initialize: (@dimension, options) ->
            @options.iconSize = new L.Point @dimension, @dimension
            @options.iconAnchor = @iconAnchor()
            @options.reducedProminence = options?.reducedProminence
            @options.pixelRatio = (el) ->
                context = el.getContext('2d')
                devicePixelRatio = window.devicePixelRatio || 1
                backingStoreRatio = context.webkitBackingStorePixelRatio || context.mozBackingStorePixelRatio || context.msBackingStorePixelRatio || context.oBackingStorePixelRatio || context.backingStorePixelRatio || 1
                return devicePixelRatio / backingStoreRatio
        options:
            className: 'leaflet-canvas-icon'
        setupCanvas: ->
            el = document.createElement 'canvas'
            context = el.getContext('2d')
            # Set ratio based on device dpi
            ratio = @options.pixelRatio(el)
            # If the IE Canvas polyfill is installed, the element needs to be specially
            # initialized.
            if G_vmlCanvasManager?
                G_vmlCanvasManager.initElement el
            @_setIconStyles el, 'icon'
            s = @options.iconSize
            # Set el width based on device dpi
            el.width = s.x * ratio
            el.height = s.y * ratio
            el.style.width = s.x + 'px'
            el.style.height = s.y + 'px'
            # Scale down to normal
            context.scale(ratio, ratio)
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

    CirclePolygon = L.Polygon.extend
        initialize: (latLng, radius, options) ->
            @circle = L.circle latLng, radius
            latLngs = @_calculateLatLngs()
            L.Polygon.prototype.initialize.call(@, [latLngs], options);
        _calculateLatLngs: ->
            bounds = @circle.getBounds()
            north = bounds.getNorth()
            east = bounds.getEast()
            center = @circle.getLatLng()
            lngRadius = east - center.lng
            latRadius = north - center.lat
            STEPS = 180
            for i in [0 ... STEPS]
                rad = (2 * i * Math.PI) / STEPS
                [center.lat + Math.sin(rad) * latRadius
                 center.lng + Math.cos(rad) * lngRadius]

    StopMarker = L.Marker.extend
        initialize: (latLng, options) ->
            markerOptions = _.extend { clickable: true }, options
            L.Marker::initialize.call @, latLng, markerOptions

    StopIcon = L.DivIcon.extend
        initialize: (types, options) ->
            className = "public-transit-stop-icon public-transit-stop-icon--#{typeToName[types[0]]}"

            # Add cluster classing if there are several different types
            if _.some(types, (type) -> type != types[0])
                className += " public-transit-stop-icon--cluster public-transit-stop-icon--cluster-#{typeToName[types[1]]}"

            iconOptions = _.extend {
                className
                iconSize: L.point [26, 26]
            }, options

            L.DivIcon::initialize.call @, iconOptions

    StopIcon.createClusterIcon = (cluster) ->
        markers = cluster.getAllChildMarkers()
        types = _.map markers, (marker) -> marker.options.vehicleType
        new StopIcon types

    StopIcon.createSubwayIcon = ->
        new StopIcon [vehicleTypes.SUBWAY]

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
        initialize: (iconSpecs, dimension, options) ->
            CanvasIcon::initialize.call @, dimension, options
            @options.iconSize = new L.Point dimension + 30, dimension + 30

            rotations = [130, 110, 90, 70, 50]
            translations = [[0, 5], [10, 7], [12, 8], [15, 10], [5, 12]]

            { @plants, @stops } = _.chain(iconSpecs)
                .slice(0, 5)
                .map (iconSpec, index) ->
                    if iconSpec.type == 'normal'
                        new draw.Plant(dimension, iconSpec.color, null, rotations[index], translations[index])
                    else if iconSpec.type == 'stop'
                        new StopIcon [iconSpec.vehicleType], translate: translations[index]
                .groupBy (icon) ->
                    if icon instanceof draw.Plant then 'plants' else 'stops'
                .value()

        createIcon: ->
            canvas = CanvasIcon::createIcon.call @

            if @stops?.length > 0
                container = document.createElement 'div'
                container.classList.add 'leaflet-marker-icon'

                if @plants?.length > 0
                    container.appendChild canvas

                @stops.forEach (stop) ->
                    { translate } = stop.options
                    icon = stop.createIcon()
                    $(icon).css(left: translate[0], top: translate[1])
                    container.appendChild icon
                container
            else
                canvas

        draw: (ctx) ->
            @plants?.forEach (plant) ->
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

    NumberCircleCanvasIcon: CanvasIcon.extend
        initialize: (@number, @dimension) ->
            CanvasIcon.prototype.initialize.call this, @dimension
            @drawer = new draw.NumberCircleMaker @dimension
        draw: (ctx) ->
            @drawer.drawNumberedCircle ctx, @number

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

    ControlWrapper: L.Control.extend
        initialize: (@view, options) ->
            L.Util.setOptions @, options
        onAdd: (map) ->
            @view.render()

    initializer: initializer
    createMarker: createMarker
    CirclePolygon: CirclePolygon
    StopIcon: StopIcon
    StopMarker: StopMarker
