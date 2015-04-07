define [
    'underscore',
    'i18next',
    'moment',
    'app/accessibility',
    'app/accessibility-sentences',
    'app/p13n',
    'app/views/base',

], (
    _,
    i18n,
    moment,
    accessibility,
    accessibilitySentences,
    p13n,
    base,
)  ->

    class AccessibilityViewpointView extends base.SMItemView
        template: 'accessibility-viewpoint-summary'

        initialize: (opts) ->
            @filterTransit = opts?.filterTransit or false
            @template = @options.template or @template
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
            @listenTo p13n, 'change', @render
            @listenTo accessibility, 'change', @render
            @collapsed = true
            @accessibilitySentences = {}
            accessibilitySentences.fetch id: @model.id,
                (data) =>
                    @accessibilitySentences = data
                    @render()
        onRender: ->
            if @model.hasAccessibilityData()
                @viewpointRegion.show new AccessibilityViewpointView()
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
                shortcomings = {}
                seen = {}
                for pid in _.keys profiles
                    shortcoming = accessibility.getShortcomings @model.get('accessibility_properties'), pid
                    if shortcoming.status != 'complete'
                        shortcomingsPending = true
                        break
                    if _.keys(shortcoming.messages).length
                        for segmentId, segmentMessages of shortcoming.messages
                            shortcomings[segmentId] = shortcomings[segmentId] or {}
                            for requirementId, messages of segmentMessages
                                gatheredMessages = []
                                for msg in messages
                                    translated = p13n.getTranslatedAttr msg
                                    if translated not of seen
                                        seen[translated] = true
                                        gatheredMessages.push msg
                                if gatheredMessages.length
                                    shortcomings[segmentId][requirementId] = gatheredMessages

            shortcomingsCount = 0
            for __, group of shortcomings
                shortcomingsCount += _.values(group).length

            if hasData
                details = []
                sentenceGroups = []
                if 'error' of @accessibilitySentences
                    details = null
                    sentenceGroups = null
                    sentenceError = true
                else
                    details = _.object _.map(
                        @accessibilitySentences.sentences,
                        (sentences, groupId) =>
                            [p13n.getTranslatedAttr(@accessibilitySentences.groups[groupId]),
                             _.map(sentences, (sentence) -> p13n.getTranslatedAttr sentence)])

                    sentenceGroups = _.map _.values(@accessibilitySentences.groups), (v) -> p13n.getTranslatedAttr(v)
                    sentenceError = false

            collapseClasses = []
            headerClasses = []
            if @collapsed
                headerClasses.push 'collapsed'
            else
                collapseClasses.push 'in'

            shortText = ''
            if hasData and _.keys(profiles).length
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
            else if _.keys(profiles).length
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
