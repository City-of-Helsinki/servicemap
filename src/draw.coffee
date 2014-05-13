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
            c.strokeStyle = 'rgba(0,0,0,1.0)'
            old_composite = c.globalCompositeOperation
            c.globalCompositeOperation = "destination-out"
            c.stroke()
            c.globalCompositeOperation = old_composite
            c.closePath()
        defaults:
            radius: 1000
            stroke: 125

    class Plant extends CanvasDrawer
        constructor: (@size, @color) ->
            @rotation = 70 + Math.random() * 40
            @ratio = @reference_length / @size
            @stem = new Stem(@size, @rotation)
        draw: (@context) ->
            @context.translate(10, 10)
            berry_point = @stem.draw(@context)
            @berry = new Berry(@size, berry_point, @color)
            @berry.draw(@context)

    exports =
        Plant: Plant
    return exports
