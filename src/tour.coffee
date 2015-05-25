define [
    'bootstrap-tour',
    'i18next',
    'app/jade',
    'app/models',
], (
    _bst, # imports Tour
    {t: t},
    jade,
    models
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
            onShow: (tour) ->
                $container = $('#search-region')
                $input = $container.find('input')
                $input.focus()
                $input.typeahead('val', '')
                # TODO: translate example query
                $input.val 'terve'
                $input.typeahead('val', 'terve').focus()
        },
        {
            element: '#browse-region'
            placement: 'right'
            backdrop: true
            onShow: (tour) ->
                $container = $('#browse-region')
                _.defer =>
                    $container.click()
        },
        {
            element: '.service-hover-color-50003'
            placement: 'right'
            backdrop: true
            onShow: ->
                $('.service-hover-color-50003').focus()
        },
        {
            element: '.leaflet-marker-icon'
            placement: 'bottom'
            backdrop: false
            onShow: (tour) ->
                unit = new models.Unit(id:8215)
                unit.fetch
                    data: include: 'root_services'
                    success: ->
                        app.commands.execute 'selectUnit', unit
        },
        {
            element: '.route-section'
            placement: 'right'
            backdrop: true
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true
            onShow: ->
                app.commands.execute 'clearSelectedUnit'
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true,
            onShow: ->
                $('#personalisation .personalisation-button').click()
            onNext: ->
                $('#personalisation .ok-button').click()
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
            onShow: ->
                app.commands.execute 'home'
                p13n.set 'skip_tour', true
            orphan: true
        },
    ]
    NUM_STEPS = STEPS.length

    startTour: ->
        # Instance the tour
        tour = new Tour
            template: (i, step) ->
                step.length = NUM_STEPS - 2
                jade.template 'tour', step
            container: '#tour-region'
            onEnd: (tour) ->
                p13n.set 'skip_tour', true
        for step, i in STEPS
            step.title = t("tour.steps.#{i}.title")
            step.content = t("tour.steps.#{i}.content")
            tour.addStep step
        unless p13n.get 'skip_tour'
            tour.start true
