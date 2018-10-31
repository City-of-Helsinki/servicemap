define (require) ->
    Backbone                 = require 'backbone'
    Marionette               = require 'backbone.marionette'
    $                        = require 'jquery'
    i18n                     = require 'i18next'
    iexhr                    = require 'iexhr'
    L                        = require 'leaflet'

    Models                   = require 'cs!app/models'
    AppState                 = require 'cs!app/app-state'
    p13n                     = require 'cs!app/p13n'
    MapView                  = require 'cs!app/map-view'
    landingPage              = require 'cs!app/landing'
    ColorMatcher             = require 'cs!app/color'
    tour                     = require 'cs!app/tour'
    debug                    = require 'cs!app/debug'
    ServiceCartView          = require 'cs!app/views/service-cart'
    NavigationLayout         = require 'cs!app/views/navigation'
    NotificationLayout       = require 'cs!app/views/notification'
    PersonalisationView      = require 'cs!app/views/personalisation'
    LanguageSelectorView     = require 'cs!app/views/language-selector'
    titleViews               = require 'cs!app/views/title'
    FeedbackFormView         = require 'cs!app/views/feedback-form'
    FeedbackConfirmationView = require 'cs!app/views/feedback-confirmation'
    TourStartButton          = require 'cs!app/views/feature-tour-start'
    disclaimers              = require 'cs!app/views/service-map-disclaimers'
    ExportingView            = require 'cs!app/views/export'
    sm                       = require 'cs!app/base'
    widgets                  = require 'cs!app/widgets'
    BaseControl              = require 'cs!app/control'
    BaseRouter               = require 'cs!app/router'
    exportUtils              = require 'cs!app/util/export'
    Analytics                = require 'cs!app/analytics'
    CancelToken              = require 'cs!app/cancel-token'
    {isFrontPage}            = require 'cs!app/util/navigation'

    DEBUG_STATE = appSettings.debug_state
    VERIFY_INVARIANTS = appSettings.verify_invariants

    LOG = debug.log

    addBackgroundLayerAsBodyClass = =>
        $body = $('body')
        isLanding = $('body').hasClass 'landing'
        $body.removeClass().addClass 'maplayer-' + p13n.get('map_background_layer')
        if isLanding
            $body.addClass 'landing'

    class AppControl extends BaseControl
        initialize: (appModels) ->
            super appModels
            #_.extend @, Backbone.Events

            @route = appModels.route
            # Selected events (always of length one)
            @selectedEvents = appModels.selectedEvents

            @_resetPendingFeedback appModels.pendingFeedback

            @listenTo p13n, 'change', (path, val) ->
                addBackgroundLayerAsBodyClass()
            @listenTo p13n, 'city-change', ->
                @_reFetchAllServiceItemUnits()

            if DEBUG_STATE
                @eventDebugger = new debug.EventDebugger appModels

        _resetPendingFeedback: (o) ->
            if o?
                @pendingFeedback = o
            else
                @pendingFeedback = new Models.FeedbackMessage()
            appModels.pendingFeedback = @pendingFeedback
            @listenTo appModels.pendingFeedback, 'sent', =>
                app.getRegion('feedbackFormContainer').show new FeedbackConfirmationView(appModels.pendingFeedback.get('unit'))

        _verifyInvariants: ->
            atMostOneIsSet = (list) ->
                _.filter(list, (collection) -> !!collection.length).length <= 1

            unless atMostOneIsSet [@selectedServices.models.concat(@serviceNodes.models), @searchResults]
                return new Error "Active service items and search results are mutually exclusive."
            unless atMostOneIsSet [@selectedPosition, @selectedUnits]
                return new Error "Selected positions/units/events are mutually exclusive."
            unless atMostOneIsSet [@searchResults, @selectedPosition]
                return new Error "Search results & selected position are mutually exclusive."
            return null

        reset: () ->
            @_setSelectedUnits()
            @_clearRadius()
            @selectedPosition.clear()
            @selectedDivision.clear()
            @route.clear()
            @units.reset []
            @serviceNodes.reset [], silent: true
            @selectedServices.reset [], silent: true
            @selectedEvents.reset []
            @_resetSearchResults()

        isStateEmpty: () ->
            @selectedPosition.isEmpty() and
            @serviceNodes.isEmpty() and
            @selectedServices.isEmpty() and
            @selectedEvents.isEmpty()

        _resetSearchResults: ->
            @searchResults.query = null
            @searchResults.reset []
            if @selectedUnits.isSet()
                @units.reset [@selectedUnits.first()]
            else if not @units.isEmpty()
                @units.reset()

        clearUnits: (opts) ->
            # Only clears selected units, and bbox units,
            # not removed serviceNode units nor search results.
            @route.clear()
            if @searchResults.isSet()
                return
            if opts?.all
                @units.clearFilters()
                @units.reset [], bbox: true
                return
            if @serviceNodes.isSet()
                return
            if @selectedServices.isSet()
                return
            if @selectedPosition.isSet() and 'distance' of @units.filters
                return
            if opts?.bbox == false and 'bbox' of @units.filters
                return
            else if opts?.bbox and 'bbox' not of @units.filters
                return
            @units.clearFilters()
            resetOpts = bbox: opts?.bbox
            if opts.silent
                resetOpts.silent = true
            if opts?.bbox
                resetOpts.noRefit = true
            if @selectedUnits.isSet()
                @units.reset [@selectedUnits.first()], resetOpts
            else
                @units.reset [], resetOpts

        highlightUnit: (unit) ->
            @units.trigger 'unit:highlight', unit

        clearSelectedUnit: ->
            @route.clear()
            @selectedUnits.each (u) -> u.set 'selected', false
            @_setSelectedUnits()
            @clearUnits all: false, bbox: false
            sm.resolveImmediately()

        selectEvent: (event) ->
            @_clearRadius()
            unit = event.getUnit()
            select = =>
                event.set 'unit', unit
                if unit?
                    @setUnit unit
                @selectedEvents.reset [event]
            if unit?
                unit.fetch
                    success: select
            else
                select()

        clearSelectedPosition: ->
            @selectedDivision.clear()
            @selectedPosition.clear()
            sm.resolveImmediately()

        resetPosition: (position) ->
            unless position?
                position = @selectedPosition.value()
                unless position?
                    position = new models.CoordinatePosition
                        isDetected: true
            position.clear()
            @listenToOnce p13n, 'position', (position) =>
                @selectPosition position
            p13n.requestLocation position

        clearSelectedEvent: ->
            @_clearRadius()
            @selectedEvents.set []
        removeUnit: (unit) ->
            @units.remove unit
            if unit == @selectedUnits.first()
                @clearSelectedUnit()
        removeUnits: (units) ->
            @units.remove units,
                silent: true
            @units.trigger 'batch-remove',
                removed: units

        _clearRadius: ->
            pos = @selectedPosition.value()
            if pos?
                hasFilter = pos.get 'radiusFilter'
                if hasFilter?
                    pos.set 'radiusFilter', null
                    @units.reset []

        _reFetchAllServiceItemUnits: ->
            if @serviceNodes.length > 0 or @selectedServices.length > 0
                @units.reset []
                @selectedServices.each (s) => @_fetchServiceItemUnits('service', s, {}, new CancelToken)
                @serviceNodes.each (s) => @_fetchServiceItemUnits('serviceNode', s, {}, new CancelToken)

        clearSearchResults: () ->
            @searchResults.query = null
            if not @searchResults.isEmpty()
                @_resetSearchResults()
            sm.resolveImmediately()

        closeSearch: ->
            if @isStateEmpty() then @home()
            sm.resolveImmediately()

        composeFeedback: (unit) ->
            if unit?
                viewOpts =
                    model: @pendingFeedback
                    unit: unit
            else
                @pendingFeedback.set 'internal_feedback', true
                viewOpts =
                    model: @pendingFeedback
                    unit: null
                    opts:
                        internalFeedback: true
            app.getRegion('feedbackFormContainer').show(
                new FeedbackFormView viewOpts
            )
            $('#feedback-form-container').on 'shown.bs.modal', ->
                $(@).children().attr('tabindex', -1).focus()
            $('#feedback-form-container').modal('show')

        closeFeedback: ->
            @_resetPendingFeedback()
            _.defer => app.getRegion('feedbackFormContainer').empty()

        showServiceMapDescription: ->
            app.getRegion('feedbackFormContainer').show new disclaimers.ServiceMapDisclaimersView()
            $('#feedback-form-container').modal('show')

        showExportingView: ->
            app.getRegion('feedbackFormContainer').show new ExportingView appModels
            $('#feedback-form-container').modal('show')

        printMap: ->
            app.getRegion('map').currentView.print()

        home: ->
            @reset()

        activateMeasuringTool: ->
            app.getRegion('map').currentView.turnOnMeasureTool()
            $(app.getRegion('navigation').currentView?.$el)?.one 'click', @deactivateMeasuringTool
            $(app.getRegion('tourStart').currentView?.$el)?.one 'click', @deactivateMeasuringTool

        deactivateMeasuringTool: ->
            app.getRegion('map').currentView.turnOffMeasureTool()
            $(app.getRegion('navigation').currentView?.$el)?.off 'click', @deactivateMeasuringTool
            if app.getRegion('tourStart').$el
                $(app.getRegion('tourStart').currentView?.$el)?.off 'click', @deactivateMeasuringTool

    app = new Marionette.Application()
    appModels = new AppState()

    cachedMapView = null
    makeMapView = (mapOpts) ->
        unless cachedMapView
            opts =
                units: appModels.units
                selectedServices: appModels.selectedServices
                serviceNodes: appModels.selectedServiceNodes
                selectedUnits: appModels.selectedUnits
                searchResults: appModels.searchResults
                selectedPosition: appModels.selectedPosition
                selectedDivision: appModels.selectedDivision
                route: appModels.route
                divisions: appModels.divisions
                dataLayers: appModels.dataLayers
                statistics: appModels.statistics
            cachedMapView = new MapView opts: opts, mapOpts: mapOpts, embedded: false
            window.mapView = cachedMapView
            map = cachedMapView.map
            pos = appModels.routingParameters.pendingPosition
            pos.on 'request', (ev) => cachedMapView.requestLocation pos
            app.getRegion('map').show cachedMapView
            f = -> landingPage.clear()
            cachedMapView.map.addOneTimeEventListener
                'zoomstart': f
                'mousedown': f
            app.request 'setMapProxy', cachedMapView.getProxy()
        cachedMapView

    setSiteTitle = (routeTitle) ->
        # Sets the page title. Should be called when the view that is
        # considered the main view changes.
        title = "#{i18n.t('general.site_title')}"
        if routeTitle
            title = "#{p13n.getTranslatedAttr(routeTitle)} | " + title
        $('head title').text title

    class AppRouter extends BaseRouter
        initialize: (options) ->
            super options

            @appModels = options.models

            refreshServiceItems = =>
                idStrings = []

                @appModels.selectedServiceNodes.pluck('id').forEach((id) -> idStrings.push("service_node:#{id}"))
                @appModels.selectedServices.pluck('id').forEach((id) -> idStrings.push("service:#{id}"))

                if idStrings.length
                    idString = idStrings.join ','
                    "unit?category=#{idString}"
                else
                    if @appModels.selectedPosition.isSet()
                        @fragmentFunctions.selectPosition()
                    else
                        ""

            blank = => ""

            @fragmentFunctions =
                selectUnit: =>
                    id = @appModels.selectedUnits.first().id
                    "unit/#{id}"
                search: (params) =>
                    query = params[0]
                    "search?q=#{query}"
                selectPosition: =>
                    slug = @appModels.selectedPosition.value().slugifyAddress()
                    "address/#{slug}"
                addService: refreshServiceItems
                removeService: refreshServiceItems
                setService: refreshServiceItems
                addServiceNode: refreshServiceItems
                removeServiceNode: refreshServiceItems
                setServiceNode: refreshServiceItems
                clearSelectedPosition: blank
                clearSelectedUnit: blank
                clearSearchResults: blank
                closeSearch: blank
                home: blank
                cancel: blank

        _getFragment: (commandString, parameters) ->
            @fragmentFunctions[commandString]?(parameters)

        navigateByCommand: (commandString, parameters) ->
            fragment = @_getFragment commandString, parameters
            if fragment?
                @navigate fragment
                p13n.trigger 'url'

        onPostRouteExecute: (context) ->
            super context
            if isFrontPage() and not p13n.get('skip_tour') and not p13n.get('hide_tour')
                tour.startTour()

    app.addRegions
        navigation: '#navigation-region'
        personalisation: '#personalisation'
        languageSelector: '#language-selector'
        serviceCart: '#service-cart'
        landingLogo: '#landing-logo'
        logo: '#persistent-logo'
        map: '#app-container'
        tourStart: '#feature-tour-start'
        feedbackFormContainer: '#feedback-form-container'
        disclaimerContainer: '#disclaimers'
        notificationContainer: '#notification-container'

    app.addInitializer (opts) ->
        window.debugAppModels = appModels
        appModels.serviceNodes.fetch
            data:
                level: 0

        appControl = new AppControl appModels
        router = new AppRouter models: appModels, controller: appControl, makeMapView: makeMapView
        appControl.router = router

        COMMANDS = [
            'addService'
            'setService'
            'removeService'

            'addServiceNode'
            'setServiceNode'
            'removeServiceNode'

            "selectUnit"
            "highlightUnit"
            "clearSelectedUnit"

            "selectPosition"
            "clearSelectedPosition"
            "resetPosition"

            "selectEvent"
            "clearSelectedEvent"

            "toggleDivision"
            "showDivisions"

            "setUnits"
            "setUnit"
            "addUnitsWithinBoundingBoxes"

            "activateMeasuringTool"
            "deactivateMeasuringTool"

            "search"
            "clearSearchResults"
            "closeSearch"

            "setRadiusFilter"
            "clearRadiusFilter"

            "home"
            "printMap"

            "composeFeedback"
            "closeFeedback"

            "showServiceMapDescription"

            "showExportingView"

            "setMapProxy"
            "addDataLayer"
            "removeDataLayer"

            "displayMessage"
            "displayNotification"

            "requestTripPlan"
        ]

        reportError = (position, command) ->
            e = appControl._verifyInvariants()
            if e
                message = "Invariant failed #{position} command #{command}: #{e.message}"
                LOG appModels
                e.message = message
                throw e

        commandInterceptor = (comm, parameters) =>
            Analytics.trackCommand comm, parameters
            args = Array.prototype.slice.call parameters
            cancelToken = new CancelToken()
            savedAppState = null
            cancelToken.on 'activated', =>
                savedAppState = appModels.clone()
                cancelToken.addHandler =>
                    appModels.setState savedAppState
            args.push cancelToken
            deferred = appControl[comm].apply(appControl, args)
            appModels.cancelToken.wrap cancelToken
            deferred?.done? =>
                navigate = true
                if parameters.length > 0
                    navigate = false if parameters[parameters.length-1]?.navigate == false
                unless navigate == false
                    router.navigateByCommand comm, parameters
            return cancelToken

        makeInterceptor = (comm) ->
            if DEBUG_STATE
                ->
                    LOG "COMMAND #{comm} CALLED"
                    cancelToken = commandInterceptor comm, arguments
                    LOG appModels
                    return cancelToken
            else if VERIFY_INVARIANTS
                ->
                    LOG "COMMAND #{comm} CALLED"
                    reportError "before", comm
                    cancelToken = commandInterceptor comm, arguments
                    reportError "after", comm
                    return cancelToken
            else
                ->
                    return commandInterceptor comm, arguments

        for comm in COMMANDS
            @reqres.setHandler comm, makeInterceptor(comm)

        navigation = new NavigationLayout appModels

        @getRegion('navigation').show navigation
        @getRegion('landingLogo').show new titleViews.LandingTitleView
        @getRegion('logo').show new titleViews.TitleView
        @getRegion('notificationContainer').show new NotificationLayout
            model: appModels.notificationMessage

        personalisation = new PersonalisationView
        @getRegion('personalisation').show personalisation

        languageSelector = new LanguageSelectorView
            p13n: p13n
        @getRegion('languageSelector').show languageSelector

        serviceCart = new ServiceCartView
            serviceNodes: appModels.selectedServiceNodes
            services: appModels.selectedServices
            selectedDataLayers: appModels.selectedDataLayers
        @getRegion('serviceCart').show serviceCart

        # The colors are dependent on the currently selected serviceNodes.
        @colorMatcher = new ColorMatcher appModels.selectedServiceNodes

        f = -> landingPage.clear()
        $('body').one "keydown", f
        $('body').one "click", f

        Backbone.history.start
            pushState: true
            root: appSettings.url_prefix

        # Prevent empty anchors from appending a '#' to the URL bar but
        # still allow external links to work.
        $('body').on 'click', 'a', (ev) ->
            target = $(ev.currentTarget)
            if not target.hasClass('external-link') and not target.hasClass('force')
                ev.preventDefault()

        @listenTo app.vent, 'site-title:change', setSiteTitle

        showButton = =>
            tourButtonView = new TourStartButton()
            app.getRegion('tourStart').show tourButtonView
            @listenToOnce tourButtonView, 'close', => app.getRegion('tourStart').empty()
        if p13n.get('skip_tour')
            showButton()
        @listenTo p13n, 'tour-skipped', =>
            showButton()

        # This one-time callback ensures the feature tour popup
        # automatically disappears once the user clicks somewhere
        # outside it.
        $(document).one 'click', (event) =>
            if !$(event.target).closest('.popover.tour').length
                if $('.popover.tour').is ':visible'
                    tour.endTour()

        app.getRegion('disclaimerContainer').show new disclaimers.ServiceMapDisclaimersOverlayView

    app.addInitializer widgets.initializer

    window.app = app

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        $('html').attr 'lang', p13n.getLanguage()
        app.start()
        if isFrontPage()
            $('body').addClass 'landing'
        addBackgroundLayerAsBodyClass()
        p13n.setVisited()
