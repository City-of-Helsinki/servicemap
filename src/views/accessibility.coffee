define ->

    class AccessibilityViewpointView extends base.SMItemView
        template: 'accessibility-viewpoint-summary'

        initialize: (opts) ->
            @filter_transit = opts?.filter_transit or false
            @template = @options.template or @template
        serializeData: ->
            profiles = p13n.get_accessibility_profile_ids @filter_transit
            profile_set: _.keys(profiles).length
            profiles: p13n.get_profile_elements profiles


    class AccessibilityDetailsView extends base.SMLayout
        className: 'unit-accessibility-details'
        template: 'unit-accessibility-details'
        regions:
            'viewpoint_region': '.accessibility-viewpoint'
        events:
            'click #accessibility-collapser': 'toggle_collapse'
        toggle_collapse: ->
            @collapsed = !@collapsed
            true # important: bubble the event
        initialize: ->
            @listenTo p13n, 'change', @render
            @listenTo accessibility, 'change', @render
            @collapsed = true
            @accessibility_sentences = {}
            accessibility_sentences.fetch id: @model.id,
                (data) =>
                    @accessibility_sentences = data
                    @render()
        onRender: ->
            if @has_data
                @viewpoint_region.show new AccessibilityViewpointView()
        serializeData: ->
            @has_data = @model.get('accessibility_properties')?.length
            profiles = p13n.get_accessibility_profile_ids()
            details = []
            sentence_groups = []
            header_classes = []
            short_text = ''

            profile_set = true
            if not _.keys(profiles).length
                profile_set = false
                profiles = p13n.get_all_accessibility_profile_ids()

            seen = {}
            shortcomings_pending = false
            shortcomings_count = 0
            if @has_data
                shortcomings = {}
                for pid in _.keys profiles
                    shortcoming = accessibility.get_shortcomings(@model.get('accessibility_properties'), pid)
                    if shortcoming.status != 'complete'
                        shortcomings_pending = true
                        break
                    if _.keys(shortcoming.messages).length
                        for segment_id, segment_messages of shortcoming.messages
                            shortcomings[segment_id] = shortcomings[segment_id] or {}
                            for requirement_id, messages of segment_messages
                                gathered_messages = []
                                for msg in messages
                                    translated = p13n.get_translated_attr msg
                                    if translated not of seen
                                        seen[translated] = true
                                        gathered_messages.push msg
                                if gathered_messages.length
                                    shortcomings[segment_id][requirement_id] = gathered_messages

                if 'error' of @accessibility_sentences
                    details = null
                    sentence_groups = null
                    sentence_error = true
                else
                    details = _.object _.map(
                        @accessibility_sentences.sentences,
                        (sentences, group_id) =>
                            [p13n.get_translated_attr(@accessibility_sentences.groups[group_id]),
                             _.map(sentences, (sentence) -> p13n.get_translated_attr sentence)])

                    sentence_groups = _.map _.values(@accessibility_sentences.groups), (v) -> p13n.get_translated_attr(v)
                    sentence_error = false

            for __, group of shortcomings
                shortcomings_count += _.values(group).length
            collapse_classes = []
            if @collapsed
                header_classes.push 'collapsed'
            else
                collapse_classes.push 'in'

            if @has_data and _.keys(profiles).length
                if shortcomings_count
                    if profile_set
                        header_classes.push 'has-shortcomings'
                        short_text = i18n.t('accessibility.shortcoming_count', {count: shortcomings_count})
                else
                    if shortcomings_pending
                        header_classes.push 'shortcomings-pending'
                        short_text = i18n.t('accessibility.pending')
                    else if profile_set
                        header_classes.push 'no-shortcomings'
                        short_text = i18n.t('accessibility.no_shortcomings')
            else if _.keys(profiles).length
                short_text = i18n.t('accessibility.no_data')

            profile_set: profile_set
            icon_class:
                if profile_set
                    p13n.get_profile_elements(profiles).pop()['icon']
                else
                    'icon-icon-wheelchair'
            shortcomings_pending: shortcomings_pending
            shortcomings_count: shortcomings_count
            shortcomings: shortcomings
            groups: sentence_groups
            details: details
            sentence_error: sentence_error
            feedback: @get_dummy_feedback()
            header_classes: header_classes.join ' '
            collapse_classes: collapse_classes.join ' '
            short_text: short_text
            has_data: @has_data

        get_dummy_feedback: ->
            now = new Date()
            yesterday = new Date(now.setDate(now.getDate() - 1))
            last_month = new Date(now.setMonth(now.getMonth() - 1))
            feedback = []
            feedback.push(
                time: moment(yesterday).calendar()
                profile: 'wheelchair user.'
                header: 'The ramp is too steep'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )
            feedback.push(
                time: moment(last_month).calendar()
                profile: 'rollator user'
                header: 'Not accessible at all and the staff are unhelpful!!!!'
                content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
            )

            feedback

        leave_feedback_on_accessibility: (event) ->
            event.preventDefault()
            # TODO: Add here functionality for leaving feedback.
