define (require) ->
    _                      = require 'underscore'
    i18n                   = require 'i18next'
    moment                 = require 'moment'
    { Model }              = require 'backbone'

    accessibility          = require 'cs!app/accessibility'
    accessibilitySentences = require 'cs!app/accessibility-sentences'
    p13n                   = require 'cs!app/p13n'
    base                   = require 'cs!app/views/base'

    class AccessibilityViewpointView extends base.SMItemView
        template: 'accessibility-viewpoint-summary'

        initialize: (opts) ->
            @filterTransit = opts?.filterTransit or false
            @template = @options.template or @template
            @listenTo p13n, 'accessibility-change', @render
        serializeData: ->
            profiles = p13n.getAccessibilityProfileIds @filterTransit
            profile_set: _.keys(profiles).length
            profiles: p13n.getProfileElements profiles


    class AccessibilityDetailsView extends base.SMLayout
        className: 'unit-accessibility-details'
        template: 'unit-accessibility-details'
        regions:
            'viewpointRegion': '.accessibility-viewpoint'
        events:
            'click #accessibility-collapser': 'toggleCollapse'
        toggleCollapse: ->
            @collapsed = !@collapsed
            true # important: bubble the event
        initialize: ->
            @accessibilitySentences = new Model data: {}
            @listenTo p13n, 'change', @render
            @listenTo accessibility, 'change', @render
            @listenTo @accessibilitySentences, 'change', @render
            @collapsed = true
            accessibilitySentences.fetch id: @model.id,
                (data) =>
                    @accessibilitySentences.set 'data', data
        onShow: ->
            profiles = p13n.getAccessibilityProfileIds()
            if @model.hasAccessibilityData() and _.keys(profiles).length
                @viewpointRegion.show new AccessibilityViewpointView()

        _calculateSentences: ->
             _.object _.map(
                 @accessibilitySentences.get('data').sentences,
                     (sentences, groupId) =>
                         [p13n.getTranslatedAttr(@accessibilitySentences.get('data').groups[groupId]),
                          _.map(sentences, (sentence) -> p13n.getTranslatedAttr sentence)])

        serializeData: ->
            hasData = @model.hasAccessibilityData()
            shortcomingsPending = false

            profiles = p13n.getAccessibilityProfileIds()
            if _.keys(profiles).length
                profileSet = true
            else
                profileSet = false
                profiles = p13n.getAllAccessibilityProfileIds()

            if hasData
                {status: status, results: shortcomings} = @model.getTranslatedShortcomings()
                shortcomingsPending = (status == 'pending')
            else
                shortcomings = {}

            shortcomingsCount = 0
            for __, group of shortcomings
                shortcomingsCount += _.values(group).length

            sentenceGroups = []
            details = []
            if 'error' of @accessibilitySentences.get('data')
                details = null
                sentenceGroups = null
                sentenceError = true
            else
                details = @_calculateSentences()
                sentenceGroups = _.map _.values(@accessibilitySentences.get('data').groups), (v) ->
                    p13n.getTranslatedAttr(v)
                sentenceError = false

            collapseClasses = []
            headerClasses = []
            if @collapsed
                headerClasses.push 'collapsed'
            else
                collapseClasses.push 'in'

            shortText = ''
            if _.keys(profiles).length
                if hasData
                    if shortcomingsCount
                        if profileSet
                            headerClasses.push 'has-shortcomings'
                            shortText = i18n.t('accessibility.shortcoming_count', {count: shortcomingsCount})
                    else
                        if shortcomingsPending
                            headerClasses.push 'shortcomings-pending'
                            shortText = i18n.t('accessibility.pending')
                        else if profileSet
                            headerClasses.push 'no-shortcomings'
                            shortText = i18n.t('accessibility.no_shortcomings')
                else
                    groups = @accessibilitySentences.get('data').groups
                    unless (groups? and _(groups).keys().length > 0)
                        shortText = i18n.t('accessibility.no_data')

            iconClass = if profileSet
                p13n.getProfileElements(profiles).pop()['icon']
            else
                'icon-icon-wheelchair'

            has_data: hasData
            profile_set: profileSet
            icon_class: iconClass
            shortcomings_pending: shortcomingsPending
            shortcomings_count: shortcomingsCount
            shortcomings: shortcomings
            groups: sentenceGroups
            details: details
            sentence_error: sentenceError
            header_classes: headerClasses.join ' '
            collapse_classes: collapseClasses.join ' '
            short_text: shortText
            feedback: @getDummyFeedback()

        getDummyFeedback: ->
            now = new Date()
            yesterday = new Date(now.setDate(now.getDate() - 1))
            lastMonth = new Date(now.setMonth(now.getMonth() - 1))
            feedback = []
            feedback.push(
                time: moment(yesterday).calendar()
                profile: 'wheelchair user.'
                header: 'The ramp is too steep'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )
            feedback.push(
                time: moment(lastMonth).calendar()
                profile: 'rollator user'
                header: 'Not accessible at all and the staff are unhelpful!!!!'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )

            feedback

        leaveFeedbackOnAccessibility: (event) ->
            event.preventDefault()
            # TODO: Add here functionality for leaving feedback.


    AccessibilityDetailsView: AccessibilityDetailsView
    AccessibilityViewpointView: AccessibilityViewpointView
