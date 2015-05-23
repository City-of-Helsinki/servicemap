define [
    'bootstrap-tour',
], (
    _bst, # imports Tour
) ->
    STEPS = [
        {
            title: 'Welcome to the Service Map'
            content: 'Content of my step'
            orphan: true
        },
        {
            title: 'Discover Service Points'
            element: '#navigation-header'
            placement: 'bottom'
            content: 'Content of my step'
        },
        {
            title: 'Search Service Points'
            element: '#search-region'
            placement: 'right'
            content: 'Content of my step'
        },
        {
            title: 'Reveal Service Points on Map'
            element: '#browse-region'
            placement: 'right'
            content: 'Content of my step'
        },
        {
            title: 'Browse Information on a Service Point'
            element: '#browse-region'
            placement: 'right'
            content: 'Content of my step'
        },
        {
            title: 'Find a Route'
            element: '#route-view-container'
            placement: 'right'
            content: 'Content of my step'
        },
        {
            title: 'Personalize Accessibility'
            element: '#personalisation'
            placement: 'left'
            content: 'Content of my step'
        },
        {
            title: 'Personalize Accessibility'
            element: '#personalisation'
            placement: 'left'
            content: 'Content of my step'
        },
        {
            title: 'Choose Appropriate View'
            element: '#service-cart'
            placement: 'left'
            content: 'Content of my step'
        },
        {
            title: 'Choose Language'
            element: '#language-selector'
            placement: 'left'
            content: 'Content of my step'
        },
        {
            title: 'Provide Feedback'
            element: '#persistent-logo .feedback-prompt'
            placement: 'left'
            content: 'Content of my step'
        },
        {
            title: 'End of Feature Tour!'
            content: 'Content of my step'
            orphan: true
        },
    ]

    startTour: ->
        # Instance the tour
        tour = new Tour
            name: 'seymour'
            storage: false
            container: '#tour-region'
            debug: true
            steps: STEPS
        # Initialize the tour
        tour.start true
        # Start the tour
        #tour.start()
