define [
    'bootstrap-tour',
    'i18next',
    'app/jade',
], (
    _bst, # imports Tour
    {t: t},
    jade,
) ->
    NUM_STEPS = 0
    STEPS = [
        {
            orphan: true
        },
        {
            element: '#navigation-header'
            placement: 'bottom'
            backdrop: true
        },
        {
            element: '#search-region'
            placement: 'right'
            backdrop: true
        },
        {
            element: '#browse-region'
            placement: 'right'
            backdrop: true
        },
        {
            element: '#browse-region'
            placement: 'right'
            backdrop: true
        },
        {
            element: '#browse-region'
            placement: 'right'
            backdrop: true
        },
        {
            element: 'body'
            placement: 'right'
            backdrop: true
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true
        },
        {
            element: '#service-cart'
            placement: 'left'
            backdrop: true
        },
        {
            element: '#language-selector'
            placement: 'left'
            backdrop: true
        },
        {
            element: '#persistent-logo .feedback-prompt'
            placement: 'left'
            backdrop: true
        },
        {
            orphan: true
        },
    ]
    NUM_STEPS = STEPS.length

    startTour: ->
        # Instance the tour
        tour = new Tour
            storage: false
            template: (i, step) ->
                step.length = NUM_STEPS
                jade.template 'tour', step
            container: '#tour-region'
            debug: true
        for step, i in STEPS
            step.title = t("tour.steps.#{i}.title")
            step.content = t("tour.steps.#{i}.content")
            tour.addStep step
        tour.start true
