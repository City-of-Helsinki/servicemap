define [
    'TweenLite'
], (
    TweenLite
) ->

    HORIZONTAL_MARGIN = 4
    DURATION_IN_SECONDS = 0.3

    getStartingLeft = (contentWidth, animation) ->
        switch animation
            when 'left' then contentWidth + HORIZONTAL_MARGIN
            when 'right' then -contentWidth - HORIZONTAL_MARGIN
            else 0

    getStartingTop = (contentHeight, animation) ->
        switch animation
            when 'left' then -contentHeight
            when 'right' then -contentHeight
            else 0

    getMoveDistanceInPx = (distance, animation) ->
        switch animation
            when 'left' then "-=#{distance}px"
            when 'right' then "+=#{distance}px"
            else 0

    render = ($container, $oldContent, $newContent, animation, callback) ->
        # Add new content to DOM after the old content.
        $container.append $newContent

        # Measurements - calculate how much the new content needs to be moved.
        contentHeight = $oldContent.height()
        contentWidth = $oldContent.width()
        moveDistance = getMoveDistanceInPx contentWidth + HORIZONTAL_MARGIN, animation

        # Move the new content to correct starting position.
        $newContent.css(
            'position': 'relative'
            'left': getStartingLeft(contentWidth, animation)
            'top': getStartingTop(contentHeight, animation)
        )

        # Make sure the old old content is has position: relative for animations.
        $oldContent.css('position': 'relative')

        # Animate old content and new content.
        TweenLite.to([$oldContent, $newContent], DURATION_IN_SECONDS, {
            left: moveDistance,
            ease: Power2.easeOut,
            onComplete: () ->
                $oldContent.remove()
                $newContent.css 'left': 0, 'top': 0
                callback?()
        })

    return {
        render: render
    }
