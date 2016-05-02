define (require) ->
    # Imports
    # External libraries
    Backbone = require 'backbone'
    Marionette = require 'backbone.marionette'
    $ = require 'jquery'
    L = require 'leaflet'
    i18n = require 'i18next'
    iexhr = require 'iexhr'

    # Internal modules
    sm = require 'cs!app/base'
    models = require 'cs!app/models'
    p13n = require 'cs!app/p13n'
    landingPage = require 'cs!app/landing'
    tour = require 'cs!app/tour'
    transit = require 'cs!app/transit'
    debug = require 'cs!app/debug'
    widgets = require 'cs!app/widgets'
    exportUtils = require 'cs!app/util/export'

    # Internal classes
    BaseControl = require 'cs!app/control'
    BaseRouter = require 'cs!app/router'
    ColorMatcher = require 'cs!app/color'

    # View modules
    titleViews = require 'cs!app/views/title'
    disclaimers = require 'cs!app/views/service-map-disclaimers'

    # Individual views
    MapView = require 'cs!app/map-view'
    ServiceCartView = require 'cs!app/views/service-cart'
    NavigationLayout = require 'cs!app/views/navigation'
    PersonalisationView = require 'cs!app/views/personalisation'
    LanguageSelectorView = require 'cs!app/views/language-selector'
    FeedbackFormView = require 'cs!app/views/feedback-form'
    FeedbackConfirmationView = require 'cs!app/views/feedback-confirmation'
    TourStartButton = require 'cs!app/views/feature-tour-start'
    ExportingView = require 'cs!app/views/export'

    # Utility functions
    {isFrontPage: isFrontPage} = require 'cs!app/util/navigation'

    # Imports end

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
                if path[path.length - 1] == 'city'
                    @_reFetchAllServiceUnits()

            if DEBUG_STATE
                @eventDebugger = new debug.EventDebugger appModels

        _resetPendingFeedback: (o) ->
            if o?
                @pendingFeedback = o
            else
                @pendingFeedback = new models.FeedbackMessage()
            appModels.pendingFeedback = @pendingFeedback
            @listenTo appModels.pendingFeedback, 'sent', =>
                app.getRegion('feedbackFormContainer').show new FeedbackConfirmationView(appModels.pendingFeedback.get('unit'))

        atMostOneIsSet: (list) ->
            _.filter(list, (o) -> o.isSet()).length <= 1

        _verifyInvariants: ->
            unless @atMostOneIsSet [@services, @searchResults]
                return new Error "Active services and search results are mutually exclusive."
            unless @atMostOneIsSet [@selectedPosition, @selectedUnits]
                return new Error "Selected positions/units/events are mutually exclusive."
            unless @atMostOneIsSet [@searchResults, @selectedPosition]
                return new Error "Search results & selected position are mutually exclusive."
            return null

        reset: () ->
            @_setSelectedUnits()
            @_clearRadius()
            @selectedPosition.clear()
            @selectedDivision.clear()
            @route.clear()
            @units.reset []
            @services.reset [], silent: true
            @selectedEvents.reset []
            @_resetSearchResults()

        isStateEmpty: () ->
            @selectedPosition.isEmpty() and
            @services.isEmpty() and
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
            # not removed service units nor search results.
            @route.clear()
            if @searchResults.isSet()
                return
            if opts?.all
                @units.clearFilters()
                @units.reset [], bbox: true
                return
            if @services.isSet()
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

        clearFilters: (key) ->
            @units.clearFilters key

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

        _reFetchAllServiceUnits: ->
            if @services.length > 0
                @units.reset []
                @services.each (s) => @_fetchServiceUnits(s)


        removeService: (serviceId) ->
            service = @services.get serviceId
            @services.remove service
            unless service.get('units')?
                return
            otherServices = @services.filter (s) => s != service
            unitsToRemove = service.get('units').reject (unit) =>
                @selectedUnits.get(unit)? or
                _(otherServices).find (s) => s.get('units').get(unit)?
            @removeUnits unitsToRemove
            if @services.size() == 0
                if @selectedPosition.isSet()
                    @selectPosition @selectedPosition.value()
                    @selectedPosition.trigger 'change:value', @selectedPosition, @selectedPosition.value()
            sm.resolveImmediately()


        clearSearchResults: () ->
            @searchResults.query = null
            if not @searchResults.isEmpty()
                @_resetSearchResults()
            sm.resolveImmediately()

        closeSearch: ->
            if @isStateEmpty() then @home()
            sm.resolveImmediately()

        composeFeedback: (unit, opts) ->
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
            _.defer => app.getRegion('feedbackFormContainer').reset()

        showServiceMapDescription: ->
            app.getRegion('feedbackFormContainer').show new disclaimers.ServiceMapDisclaimersView()
            $('#feedback-form-container').modal('show')

        showAccessibilityStampDescription: ->
            window.location.href = "http://palvelukartta.hel.fi/documentation/accessibility/#{p13n.getLanguage()}.html"

        showExportingView: ->
            app.getRegion('feedbackFormContainer').show new ExportingView appModels
            $('#feedback-form-container').modal('show')

        home: ->
            @reset()

    app = new Marionette.Application()

    appModels =
        services: new models.ServiceList()
        selectedServices: new models.ServiceList()
        units: new models.UnitList null, setComparator: true
        selectedUnits: new models.UnitList()
        selectedEvents: new models.EventList()
        searchResults: new models.SearchList [], pageSize: appSettings.page_size
        searchState: new models.WrappedModel()
        route: new transit.Route()
        routingParameters: new models.RoutingParameters()
        selectedPosition: new models.WrappedModel()
        selectedDivision: new models.WrappedModel()
        divisions: new models.AdministrativeDivisionList
        pendingFeedback: new models.FeedbackMessage()

    cachedMapView = null
    makeMapView = (mapOpts) ->
        unless cachedMapView
            opts =
                units: appModels.units
                services: appModels.selectedServices
                selectedUnits: appModels.selectedUnits
                searchResults: appModels.searchResults
                selectedPosition: appModels.selectedPosition
                selectedDivision: appModels.selectedDivision
                route: appModels.route
                divisions: appModels.divisions
            cachedMapView = new MapView opts, mapOpts
            window.mapView = cachedMapView
            map = cachedMapView.map
            pos = appModels.routingParameters.pendingPosition
            pos.on 'request', (ev) => cachedMapView.requestLocation pos
            app.getRegion('map').show cachedMapView
            f = -> landingPage.clear()
            cachedMapView.map.addOneTimeEventListener
                'zoomstart': f
                'mousedown': f
            app.commands.execute 'setMapProxy', cachedMapView.getProxy()
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
            refreshServices = =>
                ids = @appModels.selectedServices.pluck('id').join ','
                if ids.length
                    "unit?service=#{ids}"
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
                addService: refreshServices
                removeService: refreshServices
                setService: refreshServices
                clearSelectedPosition: blank
                clearSelectedUnit: blank
                clearSearchResults: blank
                closeSearch: blank
                home: blank

        _getFragment: (commandString, parameters) ->
            @fragmentFunctions[commandString]?(parameters)

        navigateByCommand: (commandString, parameters) ->
            fragment = @_getFragment commandString, parameters
            if fragment?
                @navigate fragment
                p13n.trigger 'url'

        onPostRouteExecute: ->
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

    app.addInitializer (opts) ->

        window.debugAppModels = appModels
        appModels.services.fetch
            data:
                level: 0

        appControl = new AppControl appModels
        router = new AppRouter models: appModels, controller: appControl, makeMapView: makeMapView
        appControl.router = router

        COMMANDS = [
            "addService"
            "removeService"
            "setService"

            "selectUnit"
            "highlightUnit"
            "clearSelectedUnit"

            "selectPosition"
            "clearSelectedPosition"
            "resetPosition"

            "selectEvent"
            "clearSelectedEvent"

            "toggleDivision"

            "clearFilters"

            "setUnits"
            "setUnit"
            "addUnitsWithinBoundingBoxes"

            "search"
            "clearSearchResults"
            "closeSearch"

            "setRadiusFilter"
            "home"

            "composeFeedback"
            "closeFeedback"

            "hideTour"
            "showServiceMapDescription"

            "showAccessibilityStampDescription"
            "showExportingView"

            "setMapProxy"
        ]
        reportError = (position, command) ->
            e = appControl._verifyInvariants()
            if e
                message = "Invariant failed #{position} command #{command}: #{e.message}"
                LOG appModels
                e.message = message
                throw e

        commandInterceptor = (comm, parameters) ->
            appControl[comm].apply(appControl, parameters)?.done? =>
                unless parameters[0]?.navigate == false
                    router.navigateByCommand comm, parameters

        makeInterceptor = (comm) ->
            if DEBUG_STATE
                ->
                    LOG "COMMAND #{comm} CALLED"
                    commandInterceptor comm, arguments
                    LOG appModels
            else if VERIFY_INVARIANTS
                ->
                    LOG "COMMAND #{comm} CALLED"
                    reportError "before", comm
                    commandInterceptor comm, arguments
                    reportError "after", comm
            else
                ->
                    commandInterceptor comm, arguments

        for comm in COMMANDS
            @commands.setHandler comm, makeInterceptor(comm)

        navigation = new NavigationLayout
            serviceTreeCollection: appModels.services
            selectedServices: appModels.selectedServices
            searchResults: appModels.searchResults
            selectedUnits: appModels.selectedUnits
            selectedEvents: appModels.selectedEvents
            searchState: appModels.searchState
            route: appModels.route
            units: appModels.units
            routingParameters: appModels.routingParameters
            selectedPosition: appModels.selectedPosition

        @getRegion('navigation').show navigation
        @getRegion('landingLogo').show new titleViews.LandingTitleView
        @getRegion('logo').show new titleViews.TitleView

        personalisation = new PersonalisationView
        @getRegion('personalisation').show personalisation

        languageSelector = new LanguageSelectorView
            p13n: p13n
        @getRegion('languageSelector').show languageSelector

        serviceCart = new ServiceCartView
            collection: appModels.selectedServices
        @getRegion('serviceCart').show serviceCart

        # The colors are dependent on the currently selected services.
        @colorMatcher = new ColorMatcher appModels.selectedServices

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
            @listenToOnce tourButtonView, 'close', => app.getRegion('tourStart').reset()
        if p13n.get('skip_tour')
            showButton()
        @listenTo p13n, 'tour-skipped', =>
            showButton()

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

        window.isVirtualKeyboardOpen = false
        MobileVirtualKeyboardDetector = =>
            originalHeight = $(window).height()
            window.virtualKeyboardBecameHidden = false
            currentHeight = null
            isKeyboardOpen = =>
                return false unless currentHeight?
                currentHeight < originalHeight

            (event) =>
                currentHeight = $(event.target).height()
                if isKeyboardOpen()
                    window.isVirtualKeyboardOpen = true
                    window.virtualKeyboardBecameHidden = false
                    app.vent.trigger 'virtual-keyboard:open'
                else
                    window.isVirtualKeyboardOpen = false
                    window.virtualKeyboardBecameHidden = true
                    fn = => app.vent.trigger 'virtual-keyboard:hidden'
                    _.defer fn

        detector = MobileVirtualKeyboardDetector()
        $(window).resize detector
