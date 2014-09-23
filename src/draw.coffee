define ->

    class CanvasDrawer
        reference_length: 4180
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
        starting_point: (rotation) ->
            rotation = Math.PI * rotation / 180
            bc = @berry_center()
            x = bc[0] - 0.8 * Math.cos(rotation) * @dim('top')
            y = bc[1] + Math.sin(rotation) * @dim('top') + @dim('base')
            [x, y]
        berry_center: (rotation) ->
            berry = new Berry @size
            radius = berry.defaults.radius * @ratio
            [radius, radius]
        setup: (c) ->
            c.lineJoin = 'round'
            c.strokeStyle = '#333'
            c.lineCap = 'round'
            c.lineWidth = @dim 'width'
        draw: (c) ->
            @setup(c)
            c.fillStyle = '#000'
            point = @starting_point @rotation
            @stroke_path c, (c) =>
                c.moveTo point...
                point[1] -= @dim 'base'
                c.lineTo point...
                control_point = point
                control_point[1] -= @dim 'control'
                point = @berry_center @rotation
                c.quadraticCurveTo control_point..., point...
            point

    class Berry extends CanvasDrawer
        constructor: (@size, @color, @cluster=false) ->
            @ratio = @size / @reference_length
            radius = @get_radius()
            @point = [radius, radius]
        draw: (c) ->
            unless @cluster or get_ie_version() and get_ie_version() < 9
                c.beginPath()
                # Cut out an area of the stem.
                c.arc @point..., @defaults.radius * @ratio * 1.2, 0, 2 * Math.PI
                c.fillStyle = 'rgba(0,0,0,1.0)'
                old_composite = c.globalCompositeOperation
                c.globalCompositeOperation = "destination-out"
                c.fill()
                c.globalCompositeOperation = old_composite
                c.closePath()
            c.beginPath()
            # Draw a light outline.
            c.arc @point..., @defaults.radius * @ratio, 0, 2 * Math.PI
            c.fillStyle = '#fcf7f5'
            c.fill()
            c.closePath()
            c.beginPath()
            # Draw the colored berry.
            c.fillStyle = @color
            c.arc @point..., @defaults.radius * @ratio * 0.85, 0, 2 * Math.PI
            c.fill()
            c.closePath()
        get_radius: ->
            @ratio * @defaults.radius
        defaults:
            radius: 1000
            stroke: 125

    class Plant extends CanvasDrawer
        constructor: (@size, @color, id,
                      @rotation = 67 + (id % 46),
                      @translation = [1, 1],
                      @cluster = false) ->
            @stem = new Stem(@size, @rotation)
            @berry = new Berry @size, @color, cluster=@cluster
        draw: (@context) ->
            @context.save()
            @context.translate(@translation...)
            @stem.draw @context
            @berry.draw @context
            @context.restore()
        get_width: ->
            @berry.get_radius() * 2
        get_anchor: ->
            @stem.starting_point(@rotation)

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
