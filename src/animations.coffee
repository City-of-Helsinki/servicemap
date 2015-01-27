define 'app/animations', [
    'TweenLite'
], (
    TweenLite
) ->

    HORIZONTAL_MARGIN = 4
    DURATION_IN_SECONDS = 0.3

    get_starting_left = (content_width, animation) ->
        switch animation
            when 'left' then content_width + HORIZONTAL_MARGIN
            when 'right' then -content_width - HORIZONTAL_MARGIN
            else 0

    get_starting_top = (content_height, animation) ->
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
        # Add new content to DOM after the old content.
        $container.append $new_content

        # Measurements - calculate how much the new content needs to be moved.
        content_height = $old_content.height()
        content_width = $old_content.width()
        move_distance = get_move_distance_in_px content_width + HORIZONTAL_MARGIN, animation

        # Move the new content to correct starting position.
        $new_content.css(
            'position': 'relative'
            'left': get_starting_left(content_width, animation)
            'top': get_starting_top(content_height, animation)
        )

        # Make sure the old old content is has position: relative for animations.
        $old_content.css('position': 'relative')

        # Animate old content and new content.
        TweenLite.to([$old_content, $new_content], DURATION_IN_SECONDS, {
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
