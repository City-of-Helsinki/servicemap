define (require) ->
    i18n                       = require 'i18next'
    _harvey                    = require 'harvey'

    p13n                       = require 'cs!app/p13n'
    dateformat                 = require 'cs!app/dateformat'
    draw                       = require 'cs!app/draw'
    MapView                    = require 'cs!app/map-view'
    base                       = require 'cs!app/views/base'
    RouteView                  = require 'cs!app/views/route'
    DetailsView                = require 'cs!app/views/details'
    ResourceReservationListView= require 'cs!app/views/resource-reservation'
    {AccessibilityDetailsView} = require 'cs!app/views/accessibility'
    {getIeVersion}             = require 'cs!app/base'
    {generateDepartmentDescription} = require 'cs!app/util/organization_hierarchy'

    class UnitDetailsView extends DetailsView
        id: 'details-view-container'
        className: 'navigation-element'
        template: 'details'
        regions:
            'accessibilityRegion': '.section.accessibility-section'
            'eventsRegion': '.event-list'
            'feedbackRegion': '.feedback-list'
            'resourceReservationRegion': '.section.resource-reservation-section'
        events:
            'click .back-button': 'userClose'
            'click .icon-icon-close': 'userClose'
            'click .map-active-area': 'showMap'
            'click .show-map': 'showMap'
            'click .mobile-header': 'showContent'
            'click .show-more-events': 'showMoreEvents'
            'click .disabled': 'preventDisabledClick'
            'click .leave-feedback': 'leaveFeedbackOnAccessibility'
            'click .section.main-info .description .body-expander': 'toggleDescriptionBody'
            'click .section.main-info .service-link': 'showServicesOnMap'
            'click .period-link': 'handlePeriodClick'
            'show.bs.collapse': 'scrollToExpandedSection'
            'hide.bs.collapse': '_removeLocationHash'
            'click .send-feedback': '_onClickSendFeedback'

        type: 'details'
        constructor: (args...) ->
            _.extend(this.events, DetailsView.prototype.events);
            _.extend(this.regions, DetailsView.prototype.regions);
            @events['keydown .icon-icon-close'] = @keyboardHandler @userClose, ['space', 'enter']
            super(args...)
        initialize: (options) ->
            super(options)
            @INITIAL_NUMBER_OF_EVENTS = 5
            @NUMBER_OF_EVENTS_FETCHED = 20
            @embedded = options.embedded
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits
            @listenTo @searchResults, 'reset', @render
            @currentElement

            if @model.isSelfProduced() or @model.isSupportedOperations()
                department = new models.Department(@model.get('department'))
                department.fetch
                    data: include_hierarchy: true
                    success: =>
                        @model.set 'department', department

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
            app.request 'composeFeedback', @model, null

        _updateDepartment: (department) ->
            @$el.find('#department-specifier').text(generateDepartmentDescription(department) or '')

        onShow: ->
            super()
            @listenTo @model, 'change:department', (_, department) =>
                @_updateDepartment department

            # TODO: break into domrefresh and show parts

            # Events
            #
            if @model.eventList.isEmpty()
                @listenTo @model.eventList, 'reset', (list) =>
                    @updateEventsUi list.fetchState
                    @renderEvents list
                @model.eventList.pageSize = @INITIAL_NUMBER_OF_EVENTS
                @model.getEvents()
                @model.eventList.pageSize = @NUMBER_OF_EVENTS_FETCHED
            else
                @updateEventsUi(@model.eventList.fetchState)
                @renderEvents(@model.eventList)

            if @model.feedbackList.isEmpty()
                @listenTo @model.feedbackList, 'reset', (list) =>
                    @renderFeedback @model.feedbackList
                @model.getFeedback()
            else
                @renderFeedback @model.feedbackList

            @accessibilityRegion.show new AccessibilityDetailsView
                model: @model

            view = new ResourceReservationListView model: @model
            @listenTo view, 'ready', =>
                @resourceReservationRegion.$el.removeClass('hidden')
            @resourceReservationRegion.show view

            app.vent.trigger 'site-title:change', @model.get('name')
            $('.content').focus()

        onDomRefresh: ->
            @_attachMobileHeaderListeners()

            markerCanvas = @$el.find('#details-marker-canvas').get(0)
            markerCanvasMobile = @$el.find('#details-marker-canvas-mobile').get(0)

            if !@collapsed
                context = markerCanvas.getContext('2d')
                contextMobile = markerCanvasMobile.getContext('2d')
                @_drawMarkerCanvas(context)
                @_drawMarkerCanvas(contextMobile)

            else
                contextMobile = markerCanvasMobile.getContext('2d')
                @_drawMarkerCanvas(contextMobile)


            _.defer =>
                @$el.find('a').first().focus()

        _drawMarkerCanvas: (context) =>
            conf =
                size: 40
                color: app.colorMatcher.unitColor(@model) or 'rgb(0, 0, 0)'
                id: 0
                rotation: 90
            marker = new draw.Plant conf.size, conf.color, conf.id, conf.rotation
            marker.draw context

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

            # Change focus back to list
            if @currentElement
                @currentElement.focus()

        userClose: (event) ->
            event.stopPropagation()
            app.request 'clearSelectedUnit'
            unless @searchResults.isEmpty()
                app.request 'search', @searchResults.query, {}
            @trigger 'user:close'

        preventDisabledClick: (event) ->
            event.preventDefault()
            event.stopPropagation()

        getTranslatedProvider: (providerType) ->
            # TODO: this has to be updated.
            SUPPORTED_PROVIDER_TYPES = [101, 102, 103, 104, 105]
            if providerType in SUPPORTED_PROVIDER_TYPES
                i18n.t("sidebar.provider_type.#{ providerType }")
            else

        # (Service[]) => { [periodTime: string]: [{ id: number, description: string }] }?
        _serviceDetailsToPeriods: (services) ->
            servicesWithPeriods = _.filter services, (service) -> !!service.period
            servicesSortedByPeriod = _.sortBy servicesWithPeriods, (service) ->
                [service.period[0], p13n.getTranslatedAttr(service.name)]

            periodData = _.reduce servicesSortedByPeriod, (acc, service) ->
                periodTime = "#{service.period[0]}\u2013#{service.period[1]}"

                description = p13n.getTranslatedAttr service.name
                clarification = p13n.getTranslatedAttr service.clarification

                acc[periodTime] = acc[periodTime] or []
                acc[periodTime].push
                    id: service.id
                    description: description
                    clarification: clarification
                acc
            , {}

            return if _.size(periodData) > 0 then periodData else null

        serializeData: ->
            embedded = @embedded
            data = @model.toJSON()
            # todo: implement new algorithm
            # data.provider = @getTranslatedProvider @model.get 'provider_type'
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
            data.collapsed = @collapsed || false

            data.periods = @_serviceDetailsToPeriods data.services
            data.services = _.chain data.services
                .reject (service) -> !!service.period
                .map ({ id, name, root_service_node }) -> ({
                    id,
                    name,
                    color: root_service_node or models.Service.defaultRootColor
                })
                .sortBy (service) -> p13n.getTranslatedAttr service.name
                .value()

            data.data_source = data.data_source?.replace(/^www\./, "")
            data

        renderEvents: (events) ->
            return if not events? or events.isEmpty()
            @$el.find('.section.events-section').removeClass 'hidden'
            @eventListView = @eventListView or new EventListView
                collection: events
            @eventsRegion.show @eventListView, done:
                setTimeout -> #Callback method to focus back to list element
                    $(".section.events-section").find(".show-event-details")[4].focus()
                , 0

        _feedbackSummary: (feedbackItems) ->
            count = feedbackItems.size()
            if count
                i18n.t 'feedback.count', count: count
            else
                ''

        renderFeedback: (feedbackItems) ->
            if feedbackItems?
                feedbackItems.unit = @model
                feedbackSummary = @_feedbackSummary feedbackItems
                $feedbackSection = @$el.find('.feedback-section')
                $feedbackSection.find('.short-text').text feedbackSummary
                $feedbackSection.find('.feedback-count').text feedbackSummary
                @feedbackRegion.show new FeedbackListView
                    collection: feedbackItems

        showMoreEvents: (event) ->
            @currentElement = @$el.find(".section.events-section").find(".show-event-details").last()
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

        showServicesOnMap: (event) ->
            event.preventDefault()
            id = $(event.currentTarget).data('id')
            service = _.find @model.get('services'), { id }
            app.request 'setService', new models.Service(service)

        handlePeriodClick: (event) ->
            @showServicesOnMap event

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
            app.request 'selectEvent', @model

    class EventListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'events'
        childView: EventListRowView
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
        childView: FeedbackItemView
        childViewOptions: ->
            unit: @collection.unit

    UnitDetailsView

