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

    # TODO: vary by municipality
    unit = new models.Unit id:8215
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
                $input.typeahead('val', '')
                # TODO: translate example query
                $input.typeahead('val', 'terve')
                $input.val 'terve'
                $input.click()
            onHide: ->
                $container = $('#search-region')
                $input = $container.find('input')
                $input.typeahead('val', '')
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
        },
        {
            element: '.leaflet-marker-icon'
            placement: 'bottom'
            backdrop: false
            onShow: (tour) ->
                unit.fetch
                    data: include: 'root_services,department,municipality,services'
                    success: -> app.commands.execute 'selectUnit', unit
        },
        {
            element: '.route-section'
            placement: 'right'
            backdrop: true
            onNext: ->
                app.commands.execute 'clearSelectedUnit'
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true
        },
        {
            element: '#personalisation'
            placement: 'left'
            backdrop: true,
            onShow: ->
                $('#personalisation .personalisation-button').click()
            onHide: ->
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
            onShow: (tour) ->
                app.commands.execute 'home'
                # TODO: default zoom
                p13n.set 'skip_tour', true
                $('#app-container').one 'click', =>
                    tour.end()
            onShown: (tour) ->
                $container = $ tour.getStep(tour.getCurrentStep()).container
                $step = $($container).children()
                $step.attr('tabindex', -1).focus()
                $('.tour-success', $container).on 'click', (ev) =>
                    tour.end()
                $container.find('a.service').on 'click', (ev) =>
                    tour.end()
                    app.commands.execute 'addService',
                        new models.Service(id: $(ev.currentTarget).data('service'))
            orphan: true
        },
    ]
    NUM_STEPS = STEPS.length
    getExamples = =>
        [
            {
                key: 'health'
                name: t('tour.examples.health')
                service: 25002
            },
            {
                key: 'beach'
                name: t('tour.examples.beach')
                service: 33467
            },
            {
                key: 'art'
                name: t('tour.examples.art')
                service: 25658
            },
            {
                key: 'glass_recycling'
                name: t('tour.examples.glass_recycling')
                service: 29475
            },
        ]

    startTour: ->
        selected = p13n.getLanguage()
        languages = _.chain p13n.getSupportedLanguages()
            .map (l) => l.code
            .filter (l) => l != selected
            .value()
        tour = new Tour
            template: (i, step) ->
                step.length = NUM_STEPS - 2
                step.languages = languages
                step.first = step.next == 1
                step.last = step.next == -1
                if step.last
                    step.examples = getExamples()
                jade.template 'tour', step
            storage : false
            container: '#tour-region'
            onShown: (tour) ->
                $step = $('#' + @id)
                $step.attr('tabindex', -1).focus()
            onEnd: (tour) ->
                p13n.set 'skip_tour', true
                p13n.trigger 'tour-skipped'
        for step, i in STEPS
            step.title = t("tour.steps.#{i}.title")
            step.content = t("tour.steps.#{i}.content")
            tour.addStep step
        tour.start true
