define (require) ->
    base            = require 'cs!app/views/base'
    moment          = require 'moment'
    {typeToName}    = require 'cs!app/util/transit'
    {TransitStop}   = require 'cs!app/transit'

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

            # XXX how to get multi name?
            name = _.pluck(stops, 'name')
                .join(', ')

            isWheelchairAccessible = _.every stops, (stop) -> stop.wheelchairBoarding == true
            isNotWheelchairAccessible = _.every stops, (stop) -> stop.wheelchairBoarding == false
            wheelchairAccessibility = if isWheelchairAccessible
                'accessible'
            else if isNotWheelchairAccessible
                'not-accessible'
            else
                'unknown'

            stopType = if (_.every stops, (stop) -> stop.vehicleType == stops[0].vehicleType)
                stops[0].vehicleType
            else
                'mixed'

            stops.forEach (stop) ->
                stop.stoptimes = stop.stoptimesWithoutPatterns or []
                stop.stoptimes.forEach (stoptime) ->
                    stoptime.vehicleTypeName = typeToName[stop.vehicleType]

                    if stoptime.realtime
                        if stoptime.realtimeState != 'CANCELED'
                            stoptime.departureTime = 1000 * (stoptime.serviceDay + stoptime.realtimeDeparture)
                    else
                        stoptime.departureTime = 1000 * (stoptime.serviceDay + stoptime.scheduledDeparture)

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
                name
                stopType
                wheelchairAccessibility
                stoptimes
            }

        @formatTime: (milliseconds) ->
            moment(milliseconds).format('HH:mm')

