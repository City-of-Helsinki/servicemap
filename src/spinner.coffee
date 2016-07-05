define (require) ->
    _       = require 'underscore'
    Spinner = require 'spin'

    class SMSpinner

        DEFAULTS =
            lines: 12,                      # The number of lines to draw
            length: 7,                      # The length of each line
            width: 5,                       # The line thickness
            radius: 10,                     # The radius of the inner circle
            rotate: 0,                      # Rotation offset
            corners: 1,                     # Roundness (0..1)
            color: '#000',                  # #rgb or #rrggbb
            direction: 1,                   # 1: clockwise, -1: counterclockwise
            speed: 1,                       # Rounds per second
            trail: 100,                     # Afterglow percentage
            opacity: 1/4,                   # Opacity of the lines
            fps: 20,                        # Frames per second when using setTimeout()
            zIndex: 2e9,                    # Use a high z-index by default
            className: 'spinner',           # CSS class to assign to the element
            top: '50%',                     # center vertically
            left: '50%',                    # center horizontally
            position: 'absolute'            # element position
            hideContainerContent: false   # if true, hides all child elements inside spinner container

        constructor: (options) ->
            @options = _.extend(DEFAULTS, options)
            @container = @options.container
            @finished = false

        start: ->
            if @finished then return
            if @container
                if @options.hideContainerContent
                    $(@container).children().css('visibility', 'hidden')

                @spinner = new Spinner(@options).spin(@container)

        stop: ->
            @finished = true
            if @container and @spinner
                @spinner.stop()
                if @options.hideContainerContent
                    $(@container).children().css('visibility', 'visible')

    return SMSpinner
