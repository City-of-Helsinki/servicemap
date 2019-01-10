define (require) ->
    i18n                        = require 'i18next'
    base                        = require 'cs!app/views/base'
    moment                      = require 'moment'
    {TransitStop, typeToName}   = require 'cs!app/transit'

    class PublicTransitStopsView extends base.SMItemView
        template: 'public-transit-stops'

        initialize: ->
            @listenTo @collection, 'reset', ->
                @render()

            @collection.fetch()

        serializeData: ->
            stops = super().items

            if stops.length == 0
                return {
                    name: ''
                    isWheelchairAccessible: null
                    stopType: 'mixed'
                    stoptimes: []
                }

            name = stops[0].name

            wheelchairBoarding = if _.every(stops, (stop) -> stop.wheelchairBoarding == 'POSSIBLE')
                'POSSIBLE'
            else if _.every(stops, (stop) -> stop.wheelchairBoarding == 'NOT_POSSIBLE')
                'NOT_POSSIBLE'

            accessibility = @constructor.resolveAccessibility wheelchairBoarding

            stopType = if _.every(stops, (stop) -> stop.vehicleType == stops[0].vehicleType)
                typeToName[stops[0].vehicleType]
            else
                'mixed'

            stops.forEach (stop) =>
                stop.stoptimes = stop.stoptimesWithoutPatterns or []

                stop.stoptimes.forEach (stoptime) =>
                    stoptime.vehicleTypeName = typeToName[stop.vehicleType]

                    if stoptime.realtime
                        stoptime.onRoute = (stoptime.realtimeState != 'CANCELED')

                        if stoptime.onRoute
                            stoptime.departureTime = 1000 * (stoptime.serviceDay + stoptime.realtimeDeparture)
                        else
                            stoptime.departureTime = null
                    else
                        stoptime.onRoute = true
                        stoptime.departureTime = 1000 * (stoptime.serviceDay + stoptime.scheduledDeparture)

                    stoptime.routeName = stoptime.trip?.routeShortName or ''

                    stoptime.accessibility = @constructor.resolveAccessibility stoptime.trip?.wheelchairAccessible

                    if stoptime.onRoute
                        if stoptime.pickupType == 'NONE'
                            stoptime.destination = i18n.t 'public_transit_stops.terminus'
                        else
                            stoptime.destination = stoptime.headsign
                    else
                        stoptime.destination = i18n.t 'public_transit_stops.canceled'

            stoptimes = _.chain(stops)
                .pluck 'stoptimes'
                .flatten()
                .filter 'departureTime'
                .sortBy 'departureTime'
                .slice 0, 5
                .value()

            stoptimes.forEach (stoptime) =>
                stoptime.departureTime = @constructor.formatTime stoptime.departureTime

            return {
                accessibility
                name
                stopType
                stoptimes
            }

        @formatTime: (milliseconds) ->
            if milliseconds
                time = moment milliseconds
                diff = time.diff(moment(), 'minutes')

                if diff < 1
                    i18n.t 'public_transit_stops.now'
                else if diff < 10
                    i18n.t 'public_transit_stops.in_minutes', in: diff
                else
                    time.format('HH:mm')
            else
                '--:--'

        @resolveAccessibility: (wheelchairBoarding) ->
            switch wheelchairBoarding
                when 'POSSIBLE'
                    'accessible'
                when 'NOT_POSSIBLE'
                    'not-accessible'
                else
                    'unknown'
