define (require) ->
    base            = require 'cs!app/views/base'
    moment          = require 'moment'
    {typeToName}    = require 'cs!app/util/transit'
    {TransitStop}   = require 'cs!app/transit'

    class PublicTransitStopView extends base.SMItemView
        template: 'public-transit-stop'

        # { stop: { gtfsId: string } | TransitStop }
        initialize: ({ stop }) ->
            if stop instanceof TransitStop
                @model = stop
            else
                @model = new TransitStop { gtfsId: stop.gtfsId }

            @listenTo @model, 'change', (model) ->
                @render()

            @model.fetch()

        serializeData: ->
            stop = super()

            formatTime = (milliseconds) ->
                moment(milliseconds).format('HH:mm')

            stop.vehicleTypeName = typeToName[stop.vehicleType]
            stop.externalUrl = "https://www.reittiopas.fi/pysakit/#{stop.gtfsId}"
            stop.stoptimes = stop.stoptimesWithoutPatterns or []

            stop.stoptimes.forEach (stoptime) ->
                if stoptime.realtime
                    if stoptime.realtimeState != 'CANCELED'
                        stoptime.departureTime = formatTime(1000 * (stoptime.serviceDay + stoptime.realtimeDeparture))
                else
                    stoptime.departureTime = formatTime(1000 * (stoptime.serviceDay + stoptime.scheduledDeparture))

            { stop }
