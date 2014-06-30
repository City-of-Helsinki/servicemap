define 'app/animations', ['TweenLite'], (TweenLite) ->

    get_starting_left = (content_width, animation, margin = 4) ->
        switch animation
            when 'left' then content_width + margin
            when 'right' then -content_width - margin
            else 0

    get_starting_top = (content_height, animation, margin = 4) ->
        switch animation
            when 'left' then -content_height
            when 'right' then -content_height
            else 0

    get_move_distance_in_px = (distance, animation) ->
        switch animation
            when 'left' then "-=#{distance}px"
            when 'right' then "+=#{distance}px"
            else 0

    render = ($container, $old_content, $new_content, animation, callback) ->
        #console.log 'container', $container
        #console.log 'old_content', $old_content
        #console.log 'new_content', $new_content
        #console.log 'animation', animation

        # Add new content to DOM after the old content.
        $container.append $new_content

        # Measurements - calculate how much the new content needs to be moved.
        console.log $old_content
        content_height = $old_content.height()
        content_width = $old_content.width()
        content_margin = parseInt($new_content.css('margin-left').replace('px', ''))
        move_distance = get_move_distance_in_px content_width + content_margin, animation

        #console.log 'content_height', content_height
        #console.log 'content_width', content_width
        #console.log 'content_margin', content_margin
        #console.log 'move_distance', move_distance

        # Move the new content to correct starting position.
        $new_content.css(
            'position': 'relative'
            'left': get_starting_left(content_width, animation, content_margin)
            'top': get_starting_top(content_height, animation)
        )

        #console.log 'starting left', get_starting_left(content_width, animation, content_margin)
        #console.log 'starting top', get_starting_top(content_height, animation)

        # Animate old content and new content.
        TweenLite.to([$old_content, $new_content], 0.3, {
            left: move_distance,
            ease: Power2.easeOut,
            onComplete: () ->
                $old_content.remove()
                $new_content.css 'left': 0, 'top': 0
                callback?()
        })

    return {
        render: render
    }
