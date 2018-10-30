define (require) ->
    _                      = require 'underscore'
    moment                 = require 'moment'
    i18n                   = require 'i18next'

    p13n                   = require 'cs!app/p13n'
    models                 = require 'cs!app/models'
    SMSpinner              = require 'cs!app/spinner'
    base                   = require 'cs!app/views/base'
    RouteSettingsView      = require 'cs!app/views/route-settings'
    {LoadingIndicatorView} = require 'cs!app/views/loading-indicator'

    class RouteView extends base.SMLayout
        id: 'route-view-container'
        className: 'route-view'
        template: 'route'
        regions:
            routeSettingsRegion: '.route-settings'
            routeSummaryRegion: '.route-summary'
            routeLoadingIndicator: '#route-loading-indicator'
        events:
            'click a.collapser.route': 'toggleRoute'
            'click .show-map': 'showMap'
        initialize: (options) ->
            @parentView = options.parentView
            @selectedUnits = options.selectedUnits
            @selectedPosition = options.selectedPosition
            @route = options.route
            @routingParameters = options.routingParameters
            # Debounce to avoid flooding the OTP server on small time input change.
            @listenTo @routingParameters, 'complete', _.debounce _.bind(@requestRoute, @), 300
            @listenTo p13n, 'change', @changeTransitIcon
            @listenTo @route, 'change:plan', (route) =>
                if route.has 'plan'
                    @routingParameters.set 'route', @route
                    @showRouteSummary @route
            @listenTo p13n, 'change', (path, val) =>
                # if path[0] == 'accessibility'
                #     if path[1] != 'mobility'
                #         return
                # else if path[0] != 'transport'
                #     return
                @requestRoute()

        serializeData: ->
            transit_icon: @getTransitIcon()

        getTransitIcon: () ->
            setModes = _.filter _.pairs(p13n.get('transport')), ([k, v]) -> v == true
            mode = setModes.pop()[0]
            modeIconName = mode.replace '_', '-'
            "icon-icon-#{modeIconName}"

        changeTransitIcon: ->
            $iconEl = @$el.find('#route-section-icon')
            $iconEl.removeClass().addClass @getTransitIcon()

        toggleRoute: (ev) ->
            $element = $(ev.currentTarget)
            if $element.hasClass 'collapsed'
                @showRoute()
            else
                @hideRoute()

        showMap: (ev) ->
            @parentView.showMap(ev)

        showRoute: ->
            # Route planning
            #
            lastPos = p13n.getLastPosition()
            # Ensure that any user entered position is the origin for the new route
            # so that setting the destination won't overwrite the user entered data.
            @routingParameters.ensureUnitDestination()
            @routingParameters.setDestination @model
            previousOrigin = @routingParameters.getOrigin()
            if lastPos
                if not previousOrigin
                    @routingParameters.setOrigin lastPos,
                        silent: true
                @requestRoute()
            else
                @listenTo p13n, 'position', (pos) =>
                    @requestRoute()
                @listenTo p13n, 'position_error', =>
                    @showRouteSummary null
                if not previousOrigin
                    @routingParameters.setOrigin new models.CoordinatePosition
                else
                    # This is need since we might have previous position
                    # are not pending anymore
                    @routingParameters.getOrigin().initialize()

                p13n.requestLocation @routingParameters.getOrigin()
                ,() =>
                    @routingParameters.getOrigin().setDetected(true)
                    @routeSettingsRegion.currentView.updateRegions()
                    @requestRoute()
                ,() =>
                    @routingParameters.getOrigin().setPending(false)
                    @routeSettingsRegion.currentView.updateRegions()

            @routeSettingsRegion.show new RouteSettingsView
                model: @routingParameters
                unit: @model

            @showRouteSummary null

        showRouteSummary: (route) ->
            @routeSummaryRegion.show new RoutingSummaryView
                model: @routingParameters
                noRoute: !route?

        requestRoute: ->
            if not @routingParameters.isComplete()
                return

            spinner = new SMSpinner
                container:
                    @$el.find('#route-details .route-spinner').get(0)

            spinner.start()
            @listenTo @route, 'change:plan', (plan) =>
                spinner.stop()
            @listenTo @route, 'error', =>
                spinner.stop()

            @routingParameters.unset 'route'

            opts = {}

            # TODO: verify parameters exist, pass them on to OTP
            if p13n.getAccessibilityMode('mobility') == 'wheelchair'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkBoardCost = 12*60
                opts.walkSpeed = 0.75
                opts.minTransferTime = 3*60+1

            if p13n.getAccessibilityMode('mobility') == 'reduced_mobility'
                opts.walkReluctance = 5
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 0.5

            if p13n.getAccessibilityMode('mobility') == 'rollator'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkSpeed = 0.5
                opts.walkBoardCost = 12*60

            if p13n.getAccessibilityMode('mobility') == 'stroller'
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 1

            if p13n.getTransport 'bicycle'
                opts.bicycle = true
                # TODO: take/park bike

            if p13n.getTransport 'car'
                opts.car = true

            if p13n.getTransport 'public_transport'
                publicTransportChoices = p13n.get('transport_detailed_choices').public
                selectedVehicles = _(publicTransportChoices)
                    .chain()
                    .pairs().filter(_.last).map(_.first)
                    .value()
                if selectedVehicles.length == _(publicTransportChoices).values().length
                    opts.transit = true
                else
                    opts.transit = false
                    opts.modes = selectedVehicles

            datetime = @routingParameters.getDatetime()
            opts.date = moment(datetime).format('YYYY-MM-DD')
            opts.time = moment(datetime).format('HH:mm')
            opts.arriveBy = @routingParameters.get('time_mode') == 'arrive'

            from = @routingParameters.getOrigin().otpSerializeLocation
                forceCoordinates: opts.car
            to = @routingParameters.getDestination().otpSerializeLocation
                forceCoordinates: opts.car

            @cancelToken = app.request 'requestTripPlan', from, to, opts
            @listenTo @cancelToken, 'canceled', (model, value) =>
                @routeSettingsRegion.currentView.updateRegions()
            @routeLoadingIndicator.show new LoadingIndicatorView(model: @cancelToken)

        hideRoute: ->
            @route.clear()


    class RoutingSummaryView extends base.SMItemView
        #childView: LegSummaryView
        #childViewContainer: '#route-details'
        template: 'routing-summary'
        className: 'route-summary'
        events:
            'click .route-selector a': 'switchItinerary'
            'click .accessibility-viewpoint': 'setAccessibility'

        initialize: (options) ->
            @itineraryChoicesStartIndex = 0
            @detailsOpen = false
            @skipRoute = options.noRoute
            @route = @model.get 'route'

        NUMBER_OF_CHOICES_SHOWN = 3

        LEG_MODES =
            WALK:
                icon: 'icon-icon-by-foot'
                colorClass: 'transit-walk'
                text: i18n.t('transit.walk')
            BUS:
                icon: 'icon-icon-bus'
                colorClass: 'transit-default'
                text: i18n.t('transit.bus')
            BICYCLE:
                icon: 'icon-icon-bicycle'
                colorClass: 'transit-bicycle'
                text: i18n.t('transit.bicycle')
            CAR:
                icon: 'icon-icon-car'
                colorClass: 'transit-car'
                text: i18n.t('transit.car')
            TRAM:
                icon: 'icon-icon-tram'
                colorClass: 'transit-tram'
                text: i18n.t('transit.tram')
            SUBWAY:
                icon: 'icon-icon-subway'
                colorClass: 'transit-subway'
                text: i18n.t('transit.subway')
            RAIL:
                icon: 'icon-icon-train'
                colorClass: 'transit-rail',
                text: i18n.t('transit.rail')
            FERRY:
                icon: 'icon-icon-ferry'
                colorClass: 'transit-ferry'
                text: i18n.t('transit.ferry')
            WAIT:
                icon: '',
                colorClass: 'transit-default'
                text: i18n.t('transit.wait')

        MODES_WITH_STOPS = [
            'BUS'
            'FERRY'
            'RAIL'
            'SUBWAY'
            'TRAM'
        ]

        serializeData: ->
            if @skipRoute
                return skip_route: true

            window.debugRoute = @route

            itinerary = @route.getSelectedItinerary()
            return unless itinerary?
            filteredLegs = _.filter(itinerary.legs, (leg) -> leg.mode != 'WAIT')

            mobilityAccessibilityMode = p13n.getAccessibilityMode 'mobility'
            mobilityElement = null
            if mobilityAccessibilityMode
                mobilityElement = p13n.getProfileElement mobilityAccessibilityMode
            else
                mobilityElement = LEG_MODES['WALK']

            legs = _.map(filteredLegs, (leg, index) =>
                steps = @parseSteps leg

                if leg.mode == 'WALK'
                    icon = mobilityElement.icon
                    if mobilityAccessibilityMode == 'wheelchair'
                        text = i18n.t 'transit.mobility_mode.wheelchair'
                    else
                        text = i18n.t 'transit.walk'
                else
                    icon = LEG_MODES[leg.mode].icon
                    text = LEG_MODES[leg.mode].text
                if leg.from.bogusName
                    startLocation = i18n.t "otp.bogus_name.#{leg.from.name.replace ' ', '_' }"
                if index == 0
                    startLocation = i18n.t "transit.start_location"
                start_time: moment(leg.startTime).format('LT')
                start_location: startLocation || p13n.getTranslatedAttr(leg.from.translatedName) || leg.from.name
                distance: @getLegDistance leg, steps
                icon: icon
                transit_color_class: LEG_MODES[leg.mode].colorClass
                transit_mode: text
                route: @getRouteText leg
                transit_destination: @getTransitDestination leg
                steps: steps
                has_warnings: !!_.find(steps, (step) -> step.warning)
            )

            end = {
                time: moment(itinerary.endTime).format('LT')
                name: p13n.getTranslatedAttr(@route.get('plan').to.translatedName) || @route.get('plan').to.name
                address: p13n.getTranslatedAttr(
                    @model.getDestination().get 'street_address'
                )
            }

            route = {
                duration: Math.round(itinerary.duration / 60) + ' min'
                walk_distance: (itinerary.walkDistance / 1000).toFixed(1) + 'km'
                legs: legs
                end: end
            }
            choices = @getItineraryChoices()

            skip_route: @route.get('plan').itineraries.length == 0
            profile_set: _.keys(p13n.getAccessibilityProfileIds(true)).length
            itinerary: route
            itinerary_choices: choices
            selected_itinerary_index: @route.get 'selected_itinerary'
            details_open: @detailsOpen
            current_time: moment(new Date()).format('YYYY-MM-DDTHH:mm')

        parseSteps: (leg) ->
            steps = []

            # if leg.mode in ['WALK', 'BICYCLE', 'CAR']
            #     for step in leg.steps
            #         warning = null
            #         if step.bogusName
            #             step.streetName = i18n.t "otp.bogus_name.#{step.streetName.replace ' ', '_' }"
            #         else if p13n.getTranslatedAttr step.translatedName
            #             step.streetName = p13n.getTranslatedAttr step.translatedName
            #         text = i18n.t "otp.step_directions.#{step.relativeDirection}",
            #             {street: step.streetName, postProcess: "fixFinnishStreetNames"}
            #         if 'alerts' of step and step.alerts.length
            #             warning = step.alerts[0].alertHeaderText.someTranslation
            #         steps.push(text: text, warning: warning)
            if leg.mode in MODES_WITH_STOPS and leg.intermediateStops
                if 'alerts' of leg and leg.alerts.length
                    for alert in leg.alerts
                        steps.push(
                            text: ""
                            warning: alert.alertHeaderText.someTranslation
                        )
                for stop in leg.intermediateStops
                    steps.push(
                        text: p13n.getTranslatedAttr(stop.translatedName) || stop.name
                        time: moment(stop.arrival).format('LT')
                    )
            steps

            return steps

        getLegDistance: (leg, steps) ->
            if leg.mode in MODES_WITH_STOPS
                stops = _.reject(steps, (step) -> 'warning' of step)
                return "#{stops.length} #{i18n.t('transit.stops')}"
            else
                return (leg.distance / 1000).toFixed(1) + 'km'

        getTransitDestination: (leg) ->
            if leg.mode in MODES_WITH_STOPS
                return "#{i18n.t('transit.toward')} #{leg.trip.tripHeadsign}"
            else
                return ''

        getRouteText: (leg) ->
            return unless leg.route?
            route = if leg.route.shortName?.length < 5 then leg.route.shortName else ''
            if leg.mode == 'FERRY'
                route = ''
            return route

        getItineraryChoices: ->
            numberOfItineraries = @route.get('plan').itineraries.length
            start = @itineraryChoicesStartIndex
            stop = Math.min(start + NUMBER_OF_CHOICES_SHOWN, numberOfItineraries)
            _.range(start, stop)

        switchItinerary: (event) ->
            event.preventDefault()
            @detailsOpen = true
            @route.set 'selected_itinerary', $(event.currentTarget).data('index')

        setAccessibility: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'


    RouteView
