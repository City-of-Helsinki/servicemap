define [
    'i18next',
    'harvey',
    'app/p13n',
    'app/dateformat',
    'app/draw',
    'app/map-view',
    'app/views/base',
    'app/views/route',
    'app/views/accessibility'
], (
    i18n,
    _harvey,
    p13n,
    dateformat,
    draw,
    MapView,
    base,
    RouteView,
    {AccessibilityDetailsView: AccessibilityDetailsView}
)  ->

    class UnitDetailsView extends base.SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'details'
        regions:
            'routeRegion': '.section.route-section'
            'accessibilityRegion': '.section.accessibility-section'
            'eventsRegion': '.event-list'
            'feedbackRegion': '.feedback-list'
        events:
            'click .back-button': 'userClose'
            'click .icon-icon-close': 'userClose'
            'click .map-active-area': 'showMap'
            'click .show-map': 'showMap'
            'click .mobile-header': 'showContent'
            'click .show-more-events': 'showMoreEvents'
            'click .disabled': 'preventDisabledClick'
            'click .set-accessibility-profile': 'openAccessibilityMenu'
            'click .leave-feedback': 'leaveFeedbackOnAccessibility'
            'click .section.main-info .description .body-expander': 'toggleDescriptionBody'
            'show.bs.collapse': 'scrollToExpandedSection'
            'click .send-feedback': '_onClickSendFeedback'
        type: 'details'

        initialize: (options) ->
            @INITIAL_NUMBER_OF_EVENTS = 5
            @NUMBER_OF_EVENTS_FETCHED = 20
            @embedded = options.embedded
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits
            @selectedPosition = options.selectedPosition
            @routingParameters = options.routingParameters
            @route = options.route
            @listenTo @searchResults, 'reset', @render

        _$getMobileHeader: ->
            @$el.find '.mobile-header'
        _$getDefaultHeader: ->
            @$el.find '.content .main-info .header'
        _hideHeader: ($header) ->
            $header.attr 'aria-hidden', 'true'
        _showHeader: ($header) ->
            $header.removeAttr 'aria-hidden'
        _attachMobileHeaderListeners: ->
            Harvey.attach '(max-width:767px)',
                on: =>
                    @_hideHeader @_$getDefaultHeader()
                    @_showHeader @_$getMobileHeader()
            Harvey.attach '(min-width:768px)',
                on: =>
                    @_hideHeader @_$getMobileHeader()
                    @_showHeader @_$getDefaultHeader()
        _onClickSendFeedback: (ev) ->
            app.commands.execute 'composeFeedback', @model
        onRender: ->
            # Events
            #
            if @model.eventList.isEmpty()
                @listenTo @model.eventList, 'reset', (list) =>
                    @updateEventsUi(list.fetchState)
                    @renderEvents(list)
                @model.eventList.pageSize = @INITIAL_NUMBER_OF_EVENTS
                @model.getEvents()
                @model.eventList.pageSize = @NUMBER_OF_EVENTS_FETCHED
                @model.getFeedback()
            else
                @updateEventsUi(@model.eventList.fetchState)
                @renderEvents(@model.eventList)

            if @model.feedbackList.isEmpty()
                @listenTo @model.feedbackList, 'reset', (list) =>
                    @renderFeedback @model.feedbackList
            else
                @renderFeedback @model.feedbackList

            @accessibilityRegion.show new AccessibilityDetailsView
                model: @model
            @routeRegion.show new RouteView
                model: @model
                route: @route
                parentView: @
                routingParameters: @routingParameters
                selectedUnits: @selectedUnits
                selectedPosition: @selectedPosition

            app.vent.trigger 'site-title:change', @model.get('name')
            @_attachMobileHeaderListeners()

            markerCanvas = @$el.find('#details-marker-canvas').get(0)
            markerCanvasMobile = @$el.find('#details-marker-canvas-mobile').get(0)
            context = markerCanvas.getContext('2d')
            contextMobile = markerCanvasMobile.getContext('2d')
            size = 40
            color = app.colorMatcher.unitColor(@model) or 'rgb(0, 0, 0)'
            id = 0
            rotation = 90

            marker = new draw.Plant size, color, id, rotation
            marker.draw context
            marker.draw contextMobile

            _.defer => @$el.find('a').first().focus()

        updateEventsUi: (fetchState) =>
            $eventsSection = @$el.find('.events-section')

            # Update events section short text count.
            if fetchState.count
                shortText = i18n.t 'sidebar.event_count',
                    count: fetchState.count
            else
                # Handle no events -cases.
                shortText = i18n.t('sidebar.no_events')
                @$('.show-more-events').hide()
                $eventsSection.find('.collapser').addClass('disabled')
            $eventsSection.find('.short-text').text(shortText)

            # Remove show more button if all events are visible.
            if !fetchState.next and @model.eventList.length == @eventsRegion.currentView?.collection.length
                @$('.show-more-events').hide()

        userClose: (event) ->
            event.stopPropagation()
            app.commands.execute 'clearSelectedUnit'
            unless @searchResults.isEmpty()
                app.commands.execute 'search', @searchResults.query
            @trigger 'close'

        preventDisabledClick: (event) ->
            event.preventDefault()
            event.stopPropagation()

        showMap: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: true

        showContent: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: false

        getTranslatedProvider: (providerType) ->
            SUPPORTED_PROVIDER_TYPES = [101, 102, 103, 104, 105]
            if providerType in SUPPORTED_PROVIDER_TYPES
                i18n.t("sidebar.provider_type.#{ providerType }")
            else
                ''

        serializeData: ->
            embedded = @embedded
            data = @model.toJSON()
            data.provider = @getTranslatedProvider @model.get 'provider_type'
            unless @searchResults.isEmpty()
                data.back_to = i18n.t 'sidebar.back_to.search'
            MAX_LENGTH = 20
            description = data.description
            if description
                words = description.split /[ ]+/
                if words.length > MAX_LENGTH + 1
                    data.description_ingress = words[0...MAX_LENGTH].join ' '
                    data.description_body = words[MAX_LENGTH...].join ' '
                else
                    data.description_ingress = description

            data.embedded_mode = embedded
            data.feedback_count = @model.feedbackList.length
            data

        renderEvents: (events) ->
            if events?
                unless events.isEmpty()
                    @$el.find('.section.events-section').removeClass 'hidden'
                    @eventsRegion.show new EventListView
                        collection: events

        _feedbackSummary: (feedbackItems) ->
            count = feedbackItems.size()
            if count
                i18n.t 'feedback.count', count: count
            else
                ''

        renderFeedback: (feedbackItems) ->
            if @model.get('organization') != 91
                return
            if feedbackItems?
                feedbackItems.unit = @model
                feedbackSummary = @_feedbackSummary feedbackItems
                $feedbackSection = @$el.find('.feedback-section')
                $feedbackSection.find('.short-text').text feedbackSummary
                $feedbackSection.find('.feedback-count').text feedbackSummary
                @feedbackRegion.show new FeedbackListView
                    collection: feedbackItems

        showMoreEvents: (event) ->
            event.preventDefault()
            options =
                spinnerOptions:
                    container: @$('.show-more-events').get(0)
                    hideContainerContent: true
            if @model.eventList.length <= @INITIAL_NUMBER_OF_EVENTS
                @model.getEvents({}, options)
            else
                options.success = =>
                    @updateEventsUi(@model.eventList.fetchState)
                @model.eventList.fetchNext(options)

        toggleDescriptionBody: (ev) ->
            $target = $(ev.currentTarget)
            $target.toggle()
            $target.closest('.description').find('.body').toggle()

        scrollToExpandedSection: (event) ->
            $container = @$el.find('.content').first()
            # Don't scroll if route leg is expanded.
            return if $(event.target).hasClass('steps')
            $section = $(event.target).closest('.section')
            scrollTo = $container.scrollTop() + $section.position().top
            $('#details-view-container .content').animate(scrollTop: scrollTo)

        openAccessibilityMenu: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'


    class EventListRowView extends base.SMItemView
        tagName: 'li'
        template: 'event-list-row'
        events:
            'click .show-event-details': 'showEventDetails'

        serializeData: ->
            startTime = @model.get 'start_time'
            endTime = @model.get 'end_time'
            formattedDatetime = dateformat.humanizeEventDatetime(
                startTime, endTime, 'small')
            name: p13n.getTranslatedAttr(@model.get 'name')
            datetime: formattedDatetime
            info_url: p13n.getTranslatedAttr(@model.get 'info_url')

        showEventDetails: (event) ->
            event.preventDefault()
            app.commands.execute 'selectEvent', @model

    class EventListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'events'
        itemView: EventListRowView
        initialize: (opts) ->
            @parent = opts.parent

    class FeedbackItemView extends base.SMItemView
        tagName: 'li'
        template: 'feedback-list-row'
        initialize: (options) ->
            @unit = options.unit
        serializeData: ->
            data = super()
            data.unit = @unit.toJSON()
            data

    class FeedbackListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'feedback'
        itemView: FeedbackItemView
        itemViewOptions: ->
            unit: @collection.unit

    UnitDetailsView

