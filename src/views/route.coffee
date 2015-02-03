define [
    'app/views/route-settings'
], (
    RouteSettingsView
)
->

    class RouteView extends base.SMLayout
        id: 'route-view-container'
        className: 'route-view'
        template: 'route'
        regions:
            'route_settings_region': '.route-settings'
            'route_summary_region': '.route-summary'
        events:
            'click a.collapser.route': 'toggle_route'
            'click .show-map': 'show_map'
        initialize: (options) ->
            @parent_view = options.parent_view
            @selected_units = options.selected_units
            @selected_position = options.selected_position
            @user_click_coordinate_position = options.user_click_coordinate_position
            @route = options.route
            @routing_parameters = options.routing_parameters
            @listenTo @routing_parameters, 'complete', @request_route
            @listenTo p13n, 'change', @change_transit_icon
            @listenTo @route, 'plan', (plan) =>
                @routing_parameters.set 'route', @route
                @route.draw_itinerary()
                @show_route_summary @route
            @listenTo p13n, 'change', (path, val) =>
                # if path[0] == 'accessibility'
                #     if path[1] != 'mobility'
                #         return
                # else if path[0] != 'transport'
                #     return
                @request_route()

        serializeData: ->
            transit_icon: @get_transit_icon()

        get_transit_icon: () ->
            set_modes = _.filter _.pairs(p13n.get('transport')), ([k, v]) -> v == true
            mode = set_modes.pop()[0]
            mode_icon_name = mode.replace '_', '-'
            "icon-icon-#{mode_icon_name}"

        change_transit_icon: ->
            $icon_el = @$el.find('#route-section-icon')
            $icon_el.removeClass().addClass @get_transit_icon()

        toggle_route: (ev) ->
            $element = $(ev.currentTarget)
            if $element.hasClass 'collapsed'
                @show_route()
            else
                @hide_route()

        show_map: (ev) ->
            @parent_view.show_map(ev)

        show_route: ->
            # Route planning
            #
            last_pos = p13n.get_last_position()
            # Ensure that any user entered position is the origin for the new route
            # so that setting the destination won't overwrite the user entered data.
            @routing_parameters.ensure_unit_destination()
            @routing_parameters.set_destination @model
            previous_origin = @routing_parameters.get_origin()
            if last_pos
                if not previous_origin
                    @routing_parameters.set_origin last_pos,
                        silent: true
                @request_route()
            else
                @listenTo p13n, 'position', (pos) =>
                    @request_route()
                @listenTo p13n, 'position_error', =>
                    @show_route_summary null
                if not previous_origin
                    @routing_parameters.set_origin new models.CoordinatePosition
                p13n.request_location @routing_parameters.get_origin()

            @route_settings_region.show new RouteSettingsView
                model: @routing_parameters
                unit: @model
                user_click_coordinate_position: @user_click_coordinate_position

            @show_route_summary null

        show_route_summary: (route) ->
            @route_summary_region.show new RoutingSummaryView
                model: @routing_parameters
                user_click_coordinate_position: @user_click_coordinate_position
                no_route: !route?

        request_route: ->
            @route?.clear_itinerary()
            if not @routing_parameters.is_complete()
                return

            spinner = new SMSpinner
                container:
                    @$el.find('#route-details .route-spinner').get(0)
            spinner.start()
            @listenTo @route, 'plan', (plan) =>
                spinner.stop()
            @listenTo @route, 'error', =>
                spinner.stop()

            @routing_parameters.unset 'route'

            # railway station '60.171944,24.941389'
            # satamatalo 'osm:node:347379939'
            opts = {}
            #if p13n.get_accessibility_mode('mobility') in [
            #    'wheelchair', 'stroller', 'reduced_mobility'
            #]
            #    opts.wheelchair = true

            if p13n.get_accessibility_mode('mobility') == 'wheelchair'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkBoardCost = 12*60
                opts.walkSpeed = 0.75
                opts.minTransferTime = 3*60+1

            if p13n.get_accessibility_mode('mobility') == 'reduced_mobility'
                opts.walkReluctance = 5
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 0.5

            if p13n.get_accessibility_mode('mobility') == 'rollator'
                opts.wheelchair = true
                opts.walkReluctance = 5
                opts.walkSpeed = 0.5
                opts.walkBoardCost = 12*60

            if p13n.get_accessibility_mode('mobility') == 'stroller'
                opts.walkBoardCost = 10*60
                opts.walkSpeed = 1

            if p13n.get_transport 'bicycle'
                opts.bicycle = true
            if p13n.get_transport 'car'
                opts.car = true
            if p13n.get_transport 'public_transport'
                opts.transit = true

            datetime = @routing_parameters.get_datetime()
            opts.date = moment(datetime).format('YYYY/MM/DD')
            opts.time = moment(datetime).format('HH:mm')
            opts.arriveBy = @routing_parameters.get('time_mode') == 'arrive'

            from = @routing_parameters.get_origin().otp_serialize_location
                force_coordinates: opts.car
            to = @routing_parameters.get_destination().otp_serialize_location
                force_coordinates: opts.car

            @route.request_plan from, to, opts

        hide_route: ->
            @route?.clear_itinerary window.debug_map


    class RoutingSummaryView extends base.SMItemView
        #itemView: LegSummaryView
        #itemViewContainer: '#route-details'
        template: 'routing-summary'
        className: 'route-summary'
        events:
            'click .route-selector a': 'switch_itinerary'
            'click .accessibility-viewpoint': 'set_accessibility'

        initialize: (options) ->
            @selected_itinerary_index = 0
            @itinery_choices_start_index = 0
            @user_click_coordinate_position = options.user_click_coordinate_position
            @details_open = false
            @skip_route = options.no_route
            @route = @model.get 'route'

        NUMBER_OF_CHOICES_SHOWN = 3

        LEG_MODES =
            WALK:
                icon: 'icon-icon-by-foot'
                color_class: 'transit-walk'
                text: i18n.t('transit.walk')
            BUS:
                icon: 'icon-icon-bus'
                color_class: 'transit-default'
                text: i18n.t('transit.bus')
            BICYCLE:
                icon: 'icon-icon-bicycle'
                color_class: 'transit-bicycle'
                text: i18n.t('transit.bicycle')
            CAR:
                icon: 'icon-icon-car'
                color_class: 'transit-car'
                text: i18n.t('transit.car')
            TRAM:
                icon: 'icon-icon-tram'
                color_class: 'transit-tram'
                text: i18n.t('transit.tram')
            SUBWAY:
                icon: 'icon-icon-subway'
                color_class: 'transit-subway'
                text: i18n.t('transit.subway')
            RAIL:
                icon: 'icon-icon-train'
                color_class: 'transit-rail',
                text: i18n.t('transit.rail')
            FERRY:
                icon: 'icon-icon-ferry'
                color_class: 'transit-ferry'
                text: i18n.t('transit.ferry')
            WAIT:
                icon: '',
                color_class: 'transit-default'
                text: i18n.t('transit.wait')

        MODES_WITH_STOPS = [
            'BUS'
            'FERRY'
            'RAIL'
            'SUBWAY'
            'TRAM'
        ]

        serializeData: ->
            if @skip_route
                return skip_route: true

            window.debug_route = @route

            itinerary = @route.plan.itineraries[@selected_itinerary_index]
            filtered_legs = _.filter(itinerary.legs, (leg) -> leg.mode != 'WAIT')

            mobility_accessibility_mode = p13n.get_accessibility_mode 'mobility'
            mobility_element = null
            if mobility_accessibility_mode
                mobility_element = p13n.get_profile_element mobility_accessibility_mode
            else
                mobility_element = LEG_MODES['WALK']

            legs = _.map(filtered_legs, (leg) =>
                steps = @parse_steps leg

                if leg.mode == 'WALK'
                    icon = mobility_element.icon
                    if mobility_accessibility_mode == 'wheelchair'
                        text = i18n.t 'transit.mobility_mode.wheelchair'
                    else
                        text = i18n.t 'transit.walk'
                else
                    icon = LEG_MODES[leg.mode].icon
                    text = LEG_MODES[leg.mode].text
                if leg.from.bogusName
                    start_location = i18n.t "otp.bogus_name.#{leg.from.name.replace ' ', '_' }"
                start_time: moment(leg.startTime).format('LT')
                start_location: start_location || p13n.get_translated_attr(leg.from.translatedName) || leg.from.name
                distance: @get_leg_distance leg, steps
                icon: icon
                transit_color_class: LEG_MODES[leg.mode].color_class
                transit_mode: text
                route: @get_route_text leg
                transit_destination: @get_transit_destination leg
                steps: steps
                has_warnings: !!_.find(steps, (step) -> step.warning)
            )

            end = {
                time: moment(itinerary.endTime).format('LT')
                name: p13n.get_translated_attr(@route.plan.to.translatedName) || @route.plan.to.name
                address: p13n.get_translated_attr(
                    @model.get_destination().get 'street_address'
                )
            }

            route = {
                duration: Math.round(itinerary.duration / 60) + ' min'
                walk_distance: (itinerary.walkDistance / 1000).toFixed(1) + 'km'
                legs: legs
                end: end
            }

            return {
                skip_route: false
                profile_set: _.keys(p13n.get_accessibility_profile_ids(true)).length
                itinerary: route
                itinerary_choices: @get_itinerary_choices()
                selected_itinerary_index: @selected_itinerary_index
                details_open: @details_open
                current_time: moment(new Date()).format('YYYY-MM-DDTHH:mm')
            }

        parse_steps: (leg) ->
            steps = []

            if leg.mode in ['WALK', 'BICYCLE', 'CAR']
                for step in leg.steps
                    warning = null
                    if step.bogusName
                        step.streetName = i18n.t "otp.bogus_name.#{step.streetName.replace ' ', '_' }"
                    else if p13n.get_translated_attr step.translatedName
                        step.streetName = p13n.get_translated_attr step.translatedName
                    text = i18n.t "otp.step_directions.#{step.relativeDirection}",
                        {street: step.streetName, postProcess: "fixFinnishStreetNames"}
                    if 'alerts' of step and step.alerts.length
                        warning = step.alerts[0].alertHeaderText.someTranslation
                    steps.push(text: text, warning: warning)
            else if leg.mode in MODES_WITH_STOPS and leg.intermediateStops
                if 'alerts' of leg and leg.alerts.length
                    for alert in leg.alerts
                        steps.push(
                            text: ""
                            warning: alert.alertHeaderText.someTranslation
                        )
                for stop in leg.intermediateStops
                    steps.push(
                        text: p13n.get_translated_attr(stop.translatedName) || stop.name
                        time: moment(stop.arrival).format('LT')
                    )
            else
                steps.push(text: 'No further info.')


            return steps

        get_leg_distance: (leg, steps) ->
            if leg.mode in MODES_WITH_STOPS
                stops = _.reject(steps, (step) -> 'warning' of step)
                return "#{stops.length} #{i18n.t('transit.stops')}"
            else
                return (leg.distance / 1000).toFixed(1) + 'km'

        get_transit_destination: (leg) ->
            if leg.mode in MODES_WITH_STOPS
                return "#{i18n.t('transit.toward')} #{leg.headsign}"
            else
                return ''

        get_route_text: (leg) ->
            route = if leg.route.length < 5 then leg.route else ''
            if leg.mode == 'FERRY'
                route = ''
            return route

        get_itinerary_choices: ->
            number_of_itineraries = @route.plan.itineraries.length
            start = @itinery_choices_start_index
            stop = Math.min(start + NUMBER_OF_CHOICES_SHOWN, number_of_itineraries)
            return _.range(start, stop)

        switch_itinerary: (event) ->
            event.preventDefault()
            @selected_itinerary_index = $(event.currentTarget).data('index')
            @details_open = true
            @route.draw_itinerary @selected_itinerary_index
            @render()

        set_accessibility: (event) ->
            event.preventDefault()
            p13n.trigger 'user:open'


    RouteView
