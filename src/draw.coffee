define ->

    class CanvasDrawer
        reference_length: 4500
        stroke_path: (c, callback) ->
            c.beginPath()
            callback(c)
            c.stroke()
            c.closePath()
        dim: (part) ->
            @ratio * @defaults[part]

    class Stem extends CanvasDrawer
        constructor: (@size, @rotation) ->
            @ratio = @size / @reference_length
        defaults:
            width: 250
            base: 370
            top: 2670
            control: 1030
        starting_point: ->
            [@size/2, @size]
        berry_center: (rotation) ->
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
            point = @starting_point()
            @stroke_path c, (c) =>
                c.moveTo(point...)
                point[1] -= @dim('base')
                c.lineTo(point...)
                control_point = point
                control_point[1] -= @dim('control')
                point = @berry_center(@rotation)
                c.quadraticCurveTo control_point..., point...
            point

    class Berry extends CanvasDrawer
        constructor: (@size, @point, @color) ->
            @ratio = @size / @reference_length
        draw: (c) ->
            c.beginPath()
            c.fillStyle = @color
            c.arc @point..., @defaults.radius * @ratio, 0, 2 * Math.PI
            c.fill()
            unless get_ie_version() and get_ie_version() < 9
                c.strokeStyle = 'rgba(0,0,0,1.0)'
                old_composite = c.globalCompositeOperation
                c.globalCompositeOperation = "destination-out"
                c.lineWidth = 2
                c.stroke()
                c.globalCompositeOperation = old_composite
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
            berry_point = @stem.draw(@context)
            @berry = new Berry(@size, berry_point, @color)
            @berry.draw(@context)
            @context.restore()

    draw_simple_berry = (c, x, y, radius, color) ->
        c.fillStyle = color
        c.beginPath()
        c.arc x, y, radius, 0, 2 * Math.PI
        c.fill()

    class PointCluster extends CanvasDrawer
        constructor: (@size, @colors, @positions, @radius) ->
        draw: (c) =>
            _.each @positions, (pos) =>
                draw_simple_berry c, pos..., @radius, "#000"

    class PointPlant extends CanvasDrawer
        constructor: (@size, @color, @radius) ->
            true
        draw: (c) =>
            draw_simple_berry c, 10, 10, @radius, "#f00"

    exports =
        Plant: Plant
        PointCluster: PointCluster
        PointPlant: PointPlant
    return exports
