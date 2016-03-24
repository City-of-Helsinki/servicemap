define (require) ->

    enable: ->
        detector = =>
            originalHeight = $(window).height()
            currentHeight = null
            isKeyboardOpen = =>
                return false unless currentHeight?
                currentHeight < originalHeight

            (event) =>
                currentHeight = $(event.target).height()
                if isKeyboardOpen()
                    window.isVirtualKeyboardOpen = true
                    app.vent.trigger 'virtual-keyboard:open'
                else
                    window.isVirtualKeyboardOpen = false
                    fn = => app.vent.trigger 'virtual-keyboard:hidden'
                    _.defer fn

        $(window).resize detector()
