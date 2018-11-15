define (require) ->
    _bst   = require 'bootstrap-tour'
    {t}    = require 'i18next'

    jade   = require 'cs!app/jade'
    models = require 'cs!app/models'

    # TODO: vary by municipality
    unit = new models.Unit id:8215

    STEPS = [
        {
            orphan: true
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
                _.defer ->
                    $container.click()
        },
        {
            element: '.service-node-hover-background-color-light-1405'
            placement: 'right'
            backdrop: true
        },
        {
            element: '.leaflet-canvas-icon'
            placement: 'bottom'
            backdrop: false
            onShow: (tour) ->
                deferred = $.Deferred()

                unit.fetch
                    data:
                        include: 'root_service_nodes,department,municipality,service_nodes,services'
                        geometry: true
                    success: ->
                        app.request 'selectUnit', unit, {}
                        deferred.resolve()
                    error: (errorUnit, xhr) ->
                        console.warn 'Error while fetching tour unit', { errorUnit, xhr }
                        tour.goTo tour.getCurrentStep() + 2

                deferred.promise()
        },
        {
            element: '.route-section'
            placement: 'right'
            backdrop: true
            onNext: ->
                app.request 'clearSelectedUnit'
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
            element: '.tool-header'
            placement: 'left'
            backdrop: false
        },
        {
            onShow: (tour) ->
                app.request 'home'
                # TODO: default zoom
                p13n.set 'skip_tour', true
                $('#app-container').one 'click', ->
                    tour.end()
            onShown: (tour) ->
                $container = $ tour.getStep(tour.getCurrentStep()).container
                $step = $($container).children()
                $step.attr('tabindex', -1).focus()
                $('.tour-success', $container).on 'click', (ev) ->
                    tour.end()
                $container.find('a.service-node').on 'click', (ev) ->
                    tour.end()
                    app.request 'addServiceNode',
                        new models.ServiceNode(id: $(ev.currentTarget).data('service-node')),
                        {}
            orphan: true
        },
    ]

    NUM_STEPS = STEPS.length

    getExamples = =>
        [
            {
                key: 'health'
                name: t('tour.examples.health')
                serviceNode: 991
            },
            {
                key: 'beach'
                name: t('tour.examples.beach')
                serviceNode: 689
            },
            {
                key: 'art'
                name: t('tour.examples.art')
                serviceNode: 2006
            },
            {
                key: 'glass_recycling'
                name: t('tour.examples.glass_recycling')
                serviceNode: 40
            },
        ]

    tour = null

    startTour: ->
        selected = p13n.getLanguage()
        languages = _.chain p13n.getSupportedLanguages()
            .map (language) -> language.code
            .reject (languageCode) -> languageCode == selected
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
            storage: false
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

    endTour: ->
        tour?.end()
