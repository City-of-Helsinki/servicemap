define [
    'app/views/base',
    'app/tour'
],
(
    base,
    tour,
) ->

    class TourStartButton extends base.SMItemView
        className: 'feature-tour-start'
        template: 'feature-tour-start'
        events:
            'click .close-button' : 'hideTour'
            'click .prompt-button' : 'showTour'
        hideTour: (ev) ->
            p13n.set 'hide_tour', true
            @trigger 'close'
            ev.stopPropagation()
        showTour: (ev) ->
            tour.startTour()
            @trigger 'close'
