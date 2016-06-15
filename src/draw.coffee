define [
    'cs!app/base',
    'cs!app/p13n',
    'underscore'
],
(
    {getIeVersion: getIeVersion},
    p13n,
    _
) ->

    # Define colors for berries by background-layer
    COLORS =
        servicemap:
            strokeStyle: '#333'
            fillStyle: '#000'
        ortographic:
            strokeStyle: '#fff'
            fillStyle: '#000'
        guidemap:
            strokeStyle: '#333'
            fillStyle: '#000'
        accessible_map:
            strokeStyle: '#1964e6'
            fillStyle: '#1964e6'
            outlineStyle: '#f9f9ea'
    getColor = (property) ->
        background = p13n.get('map_background_layer')
        return COLORS[background][property]

    ACCESSIBLE_MARKER_DIMS =
        outlineWidth: 6
        colorDisc: 12
        paddingDisc: 28
        berryHeight: 45
    isAccessibleMap = () ->
        return p13n.get('map_background_layer') == 'accessible_map'

    class CanvasDrawer
        referenceLength: 4500
        strokePath: (c, callback) ->
            c.beginPath()
            callback(c)
            c.stroke()
            c.closePath()
        dim: (part) ->
            @ratio * @defaults[part]
        accessibleDim: (part) ->
            ACCESSIBLE_MARKER_DIMS[part] * @size / 100

    class Stem extends CanvasDrawer
        constructor: (@size, @rotation) ->
            @ratio = @size / @referenceLength
        defaults:
            width: 250
            base: 370
            top: 2670
            control: 1030


        startingPoint: ->
            [@size/2, @size]
        berryCenter: (rotation) ->
            unless isAccessibleMap()
                rotation = Math.PI * rotation / 180
                x = 0.8 * Math.cos(rotation) * @dim('top') + (@size / 2)
                y = - Math.sin(rotation) * @dim('top') + @size - @dim('base')
            else
                # Stem is always straight for accessible map
                x = @size / 2
                y = @accessibleDim('berryHeight')
            [x, y]
        setup: (c) ->
            c.lineJoin = 'round'
            c.strokeStyle = getColor('strokeStyle')
            c.lineCap = 'round'
            c.lineWidth = @dim('width')
        draw: (c) ->
            if isAccessibleMap()
                return @drawHighContrastStem(c)
            @setup(c)
            c.fillStyle = '#000'
            point = @startingPoint()
            @strokePath c, (c) =>
                c.moveTo(point...)
                point[1] -= @dim('base')
                c.lineTo(point...)
                controlPoint = point
                controlPoint[1] -= @dim('control')
                point = @berryCenter(@rotation)
                c.quadraticCurveTo controlPoint..., point...
            point
        drawHighContrastStem: (c) ->
            endPoint = [@size/2, 2 * @accessibleDim('paddingDisc') + 5 * @accessibleDim('outlineWidth') - 1]
            @setup c
            # Draw stem outline
            c.lineWidth = 3 * @accessibleDim('outlineWidth')
            c.strokeStyle = getColor 'outlineStyle'
            c.lineJoin = 'miter'
            c.beginPath()
            c.moveTo @startingPoint()...
            c.lineTo endPoint...
            c.stroke()
            c.closePath()
            # Draw stem
            @setup c
            c.lineWidth = @accessibleDim('outlineWidth')
            c.lineJoin = 'miter'
            c.beginPath()
            endPoint[1] = 2 * @accessibleDim('paddingDisc') + 3 * @accessibleDim('outlineWidth')
            c.moveTo @startingPoint()...
            c.lineTo endPoint...
            c.stroke()
            c.closePath()

    class Berry extends CanvasDrawer
        constructor: (@size, @point, @color) ->
            @ratio = @size / @referenceLength
        draw: (c) ->
            if isAccessibleMap()
                return @drawHighContrastBerry(c)
            c.beginPath()
            c.fillStyle = @color
            c.arc @point..., @defaults.radius * @ratio, 0, 2 * Math.PI
            c.fill()
            unless getIeVersion() and getIeVersion() < 9
                c.strokeStyle = 'rgba(0,0,0,1.0)'
                oldComposite = c.globalCompositeOperation
                c.globalCompositeOperation = "destination-out"
                c.lineWidth = 1.5
                c.stroke()
                c.globalCompositeOperation = oldComposite
            c.closePath()
            c.beginPath()
            c.arc @point..., @defaults.radius * @ratio - 1, 0, 2 * Math.PI
            c.strokeStyle = '#fcf7f5'
            c.lineWidth = 1
            c.stroke()
            c.closePath()
        drawHighContrastBerry: (c) ->
            # Draw white disc
            c.beginPath()
            c.fillStyle = '#fff'
            c.arc @point..., @accessibleDim('paddingDisc'), 0, 2 * Math.PI
            c.fill()
            c.closePath()
            # Draw colour disc
            c.beginPath()
            c.fillStyle = @color
            c.arc @point..., @accessibleDim('colorDisc'), 0, 2 * Math.PI
            c.fill()
            c.closePath()
            # Draw inner outline
            c.beginPath()
            c.strokeStyle = getColor 'strokeStyle'
            c.lineWidth = @accessibleDim 'outlineWidth'
            c.arc @point..., @accessibleDim('paddingDisc'), 0 , 2 * Math.PI
            c.stroke()
            c.closePath()
            # Draw outer outline
            c.beginPath()
            c.strokeStyle = getColor 'outlineStyle'
            c.arc @point..., @accessibleDim('paddingDisc') + @accessibleDim('outlineWidth'), 0, 2 * Math.PI
            c.stroke()
            c.closePath()
        defaults:
            radius: 1000
            stroke: 125

    class Plant extends CanvasDrawer
        constructor: (@size, @color, id,
                      @rotation = 70 + (id % 40),
                      @translation = [0, -3]) ->
            @stem = new Stem(@size, @rotation)
        draw: (@context) ->
            if isAccessibleMap()
                return @drawHighContrastPlant(@context)
            @context.save()
            @context.translate(@translation...)
            berryPoint = @stem.draw(@context)
            @berry = new Berry(@size, berryPoint, @color)
            @berry.draw(@context)
            @context.restore()
        drawHighContrastPlant: (@context) ->
            @context.save()
            @context.translate @translation...
            berryPoint = @stem.berryCenter()
            @berry = new Berry(@size, berryPoint, @color)
            @berry.draw(@context)
            @stem.draw(@context)
            @context.restore()

    drawSimpleBerry = (c, x, y, radius, color) ->
        c.fillStyle = color
        c.beginPath()
        c.arc x, y, radius, 0, 2 * Math.PI
        c.fill()

    class PointCluster extends CanvasDrawer
        constructor: (@size, @colors, @positions, @radius) ->
        draw: (c) =>
            _.each @positions, (pos) =>
                drawSimpleBerry c, pos..., @radius, "#000"

    class PointPlant extends CanvasDrawer
        constructor: (@size, @color, @radius) ->
            true
        draw: (c) =>
            drawSimpleBerry c, 10, 10, @radius, "#f00"

    exports =
        Plant: Plant
        PointCluster: PointCluster
        PointPlant: PointPlant
    return exports
