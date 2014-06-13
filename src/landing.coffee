define 'app/landing', () ->

    clear_landing_page = ->
        # The transitions triggered by removing the class landing from body are defined
        # in the file landing-page.less.
        # When key animations have ended a 'landing-page-cleared' event is triggered.
        if $('body').hasClass('landing')
            $('body').removeClass('landing')
            $('.service-sidebar').on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', (event) ->
                if not event.originalEvent
                    return
                if event.originalEvent.propertyName is 'top'
                    app.vent.trigger('landing-page-cleared')
                    $(@).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitnd')
                )
    return {
        clear: clear_landing_page
    }
