define (require) ->
    base = require 'cs!app/views/base'
    tour = require 'cs!app/tour'

    class TourStartButton extends base.SMItemView
        className: 'feature-tour-start'
        template: 'feature-tour-start'
        events:
            'click .close-button' : 'hideTour'
            'click .prompt-button' : 'showTour'
        hideTour: (event) ->
            p13n.set 'hide_tour', true
            @trigger 'close'
            event.stopPropagation()
        showTour: (event) ->
            event.preventDefault()
            event.stopPropagation()
            tour.startTour()
            @trigger 'close'
