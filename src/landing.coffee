define ->

    clearLandingPage = ->
        # The transitions triggered by removing the class landing from body are defined
        # in the file landing-page.less.
        # When key animations have ended a 'landing-page-cleared' event is triggered.
        if $('body').hasClass('landing')
            $('body').removeClass('landing')
            $('#navigation-region').one('transitionend webkitTransitionEnd otransitionend oTransitionEnd MSTransitionEnd', (event) ->
                app.vent.trigger('landing-page-cleared')
                $(@).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitnd')
                )
    return {
        clear: clearLandingPage
    }
