define [
    'cs!app/models',
    'cs!app/p13n',
    'cs!app/map-view',
    'cs!app/landing',
    'cs!app/color',
    'cs!app/tour',
    'backbone',
    'backbone.marionette',
    'jquery',
    'i18next',
    'cs!app/uservoice',
    'cs!app/transit',
    'cs!app/debug',
    'iexhr',
    'cs!app/views/service-cart',
    'cs!app/views/navigation',
    'cs!app/views/personalisation',
    'cs!app/views/language-selector',
    'cs!app/views/title',
    'cs!app/views/feedback-form',
    'cs!app/views/feedback-confirmation',
    'cs!app/views/feature-tour-start',
    'cs!app/views/service-map-disclaimers',
    'cs!app/views/export',
    'cs!app/base',
    'cs!app/widgets',
    'cs!app/control',
    'cs!app/router',
    'cs!app/util/export',
    'cs!app/util/navigation',
    'leaflet',
    'leaflet-image',
    'leaflet-image-ie',
    'cs!app/draw'
],
(
    Models,
    p13n,
    MapView,
    landingPage,
    ColorMatcher,
    tour,
    Backbone,
    Marionette,
    $,
    i18n,
    uservoice,
    transit,
    debug,
    iexhr,
    ServiceCartView,
    NavigationLayout,
    PersonalisationView,
    LanguageSelectorView,
    titleViews,
    FeedbackFormView,
    FeedbackConfirmationView,
    TourStartButton,
    disclaimers,
    ExportingView,
    sm,
    widgets,
    BaseControl,
    BaseRouter,
    exportUtils,
    {isFrontPage: isFrontPage},
    L,
    leafletImage,
    leafletImageIe,
    draw
) ->

    # Allow calling original getBounds when needed.
    # (leaflet.activearea overrides getBounds)
    L.Map.prototype._originalGetBounds = L.Map.prototype.getBounds

    DEBUG_STATE = appSettings.debug_state
    VERIFY_INVARIANTS = appSettings.verify_invariants

    LOG = debug.log

    ieVersion = sm.getIeVersion()
    if ieVersion == 10
        leafletImage = leafletImageIe

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
                @pendingFeedback = new Models.FeedbackMessage()
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
        services: new Models.ServiceList()
        selectedServices: new Models.ServiceList()
        units: new Models.UnitList null, setComparator: true
        selectedUnits: new Models.UnitList()
        selectedEvents: new Models.EventList()
        searchResults: new Models.SearchList [], pageSize: appSettings.page_size
        searchState: new Models.WrappedModel()
        route: new transit.Route()
        routingParameters: new Models.RoutingParameters()
        selectedPosition: new Models.WrappedModel()
        selectedDivision: new Models.WrappedModel()
        divisions: new models.AdministrativeDivisionList
        pendingFeedback: new Models.FeedbackMessage()

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

    window.printTest = (bulb) =>
        if window.makingPrint or window.printed == false
            return

        window.makingPrint = true
        window.printed = false
        if !bulb
            alert 'Please print with the "Print" button'

        createSvgMarker= (num) ->
            "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' height='100' width='100'%3E%3Ccircle cx='50' cy='50' r='25' stroke='black' stroke-width='3' fill='black'%3E%3C/circle%3E%3Ctext x='5' y='60' stroke='black' fill='white' font-size='38'%3E"+num+"%3C/text%3E%3C/svg%3E"

        map = window.mapView.map
        oldMarkers = window.mapView.allMarkers._featureGroup._layers;
        markers = Object.assign({}, oldMarkers);
        listOfUnits = document.createElement('div')
        listOfUnits.id = 'list-of-units';
        document.getElementsByTagName('body')[0].appendChild(listOfUnits);

        # Counter for printed markers
        vid = (() ->
            num = 0
            inc = () -> ++num
            inc
            )()
        window.printedMarkers = [];
        window.printIcons = [];
        for own id, marker of markers
            # Settings altered for printing. These will be reset after printing.
            printStore = {storeAttributes: ['iconSize', 'iconAnchor'] }
            for att in printStore.storeAttributes
                if marker.options.icon.options[att]
                    printStore[att] = marker.options.icon.options[att]
            marker.options.icon.options.printStore = printStore

            # Icon size smaller than 70 causes clusters to misbehave when zooming in after printing
            iconSize = 70
            marker.options.icon.options.iconSize = new L.Point(iconSize, iconSize)
            # Adjust the icon anchor to correct place
            marker.options.icon.options.iconAnchor = new L.Point(3*iconSize/4, iconSize/4)

            #
            bounds = map.getPixelBounds()
            sw = map.unproject(bounds.getBottomLeft())
            ne = map.unproject(bounds.getTopRight())
            if(new L.LatLngBounds(sw, ne).contains(marker.getLatLng()))
                marker.vid = vid()
                # Don't throw the actual icon away
                marker._iconStore = marker._icon

                canvasIcon = document.createElement('canvas')
                canvasIcon.height = iconSize
                canvasIcon.width = iconSize
                ctx = canvasIcon.getContext('2d')
                drawer = new draw.NumberCircleMaker(iconSize/2);
                drawer.drawNumberedCircle(ctx, marker.vid)
                marker._icon = canvasIcon
                marker._icon.src = canvasIcon.toDataURL();

                # With this kind of marker Firefox doesn't miss markers but creating the leaflet-image
                # takes much longer
                #marker._icon = document.createElement 'img'
                #marker._icon.src = 'http://localhost:8000/leaflet/images/marker-icon-2x.png'

                markerLegend = document.createElement 'div'
                markerLegend.innerHTML = "<div>" + marker.vid + ": " + "</div>";

                getClusteredUnits = (markerCluster) ->
                    unitNames = []
                    for own mid, mm of markerCluster._markers
                        unitNames.push mm.unit.attributes.name.fi
                    for own mcid, mc of markerCluster._childClusters
                        unitNames = unitNames.concat getClusteredUnits(mc)
                    unitNames

                if marker instanceof L.MarkerCluster
                    # Adjust the icon anchor position for clusters with these magic numbers
                    marker.options.icon.options.iconAnchor = new L.Point(5*iconSize/6, iconSize / 6)
                    unitNames = getClusteredUnits(marker)
                    for name in unitNames
                        div = document.createElement 'div'
                        div.className = 'printed-unit-name'
                        div.textContent = name
                        markerLegend.appendChild div

                else
                    div = document.createElement 'div'
                    div.className = 'printed-unit-name'
                    div.textContent = marker.unit.attributes.name.fi
                    markerLegend.appendChild div
                listOfUnits.appendChild(markerLegend)
            else # Markers outside the current view

        leafletImage map, (err, canvas) =>
            # now you have canvas
            # example thing to do with that canvas:
            console.log canvas, err
            img = document.createElement 'img'
            img.src = canvas.toDataURL()
            document.getElementById('images').appendChild img
            window.makingPrint = false

    window.onAfterPrint = () =>
        if window.makingPrint
            return
        markers = window.mapView.allMarkers._featureGroup._layers;
        for own id, marker of markers
            # Remove the printed marker icon
            if marker._iconStore
                marker._icon.remove()
                delete marker._icon
                marker._icon = marker._iconStore
                delete marker._iconStore
            # Reset icon options
            if marker.options.icon.options.printStore
                printStore = marker.options.icon.options.printStore
                for att in printStore.storeAttributes
                    delete marker.options.icon.options[att]
                    if printStore[att]
                        marker.options.icon.options[att] = printStore[att]
                delete marker.options.icon.options.printStore

        images = document.getElementById('images')
        images?.innerHTML = ''
        listOfUnits = document.getElementById('list-of-units')
        listOfUnits?.remove()
        window.printed = true

    # Add print event listeners
    (() ->
        # webkit
        if window.matchMedia
            mediaQueryList = window.matchMedia('print')
            mediaQueryList.addListener (mql) ->
                if mql.matches
                    window.printTest()
                else
                    window.onAfterPrint()

        # IE + FF
        window.onbeforeprint = window.printTest
        window.onafterprint = window.onAfterPrint

    )()



    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        $('html').attr 'lang', p13n.getLanguage()
        app.start()
        if isFrontPage()
            $('body').addClass 'landing'
        addBackgroundLayerAsBodyClass()
        p13n.setVisited()
        uservoice.init(p13n.getLanguage())
