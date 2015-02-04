define ->

    class CanvasDrawer
        referenceLength: 4500
        strokePath: (c, callback) ->
            c.beginPath()
            callback(c)
            c.stroke()
            c.closePath()
        dim: (part) ->
            @ratio * @defaults[part]

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
            rotation = Math.PI * rotation / 180
            x = 0.8 * Math.cos(rotation) * @dim('top') + (@size / 2)
            y = - Math.sin(rotation) * @dim('top') + @size - @dim('base')
            [x, y]
        setup: (c) ->
            c.lineJoin = 'round'
            c.strokeStyle = '#333'
            c.lineCap = 'round'
            c.lineWidth = @dim('width')
        draw: (c) ->
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

    class Berry extends CanvasDrawer
        constructor: (@size, @point, @color) ->
            @ratio = @size / @referenceLength
        draw: (c) ->
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
        defaults:
            radius: 1000
            stroke: 125

    class Plant extends CanvasDrawer
        constructor: (@size, @color, id,
                      @rotation = 70 + (id % 40),
                      @translation = [0, -3]) ->
            @stem = new Stem(@size, @rotation)
        draw: (@context) ->
            @context.save()
            @context.translate(@translation...)
            berryPoint = @stem.draw(@context)
            @berry = new Berry(@size, berryPoint, @color)
            @berry.draw(@context)
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
