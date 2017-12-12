define (require) ->
    base            = require 'cs!app/views/base'
    moment          = require 'moment'
    {typeToName}    = require 'cs!app/util/gtfs-route-types'

    class PublicTransitStopsListView extends base.SMLayout
        template: 'public-transit-stops-list'
        regions:
            stopContent: '.stop-content'
        events: ->
            'click .stop-name': 'selectStop'
        initialize: (opts) ->
            @stops = opts.stops
            @route = opts.route
        serializeData: ->
            thisStops = @stops
            for stop in thisStops
                stop.className = typeToName[stop.vehicleType]
            stops: thisStops
        selectStop: (ev) ->
            stopId = $(ev.currentTarget).data('stop-id')
            foundStop
            for stop in @stops
                if stop.id == stopId
                    foundStop = stop
                    break
            if foundStop
                @stopContent.show new PublicTransitStopView {stop, @route}

    class PublicTransitStopView extends base.SMItemView
        template: 'public-transit-stop'
        initialize: (opts) ->
            @stop = opts.stop
            @listenToOnce opts.route, 'change:stop', (route) ->
                # potentially bad idea to use listenToOnce, but stopListening on view destroy did not work
                if route.has 'stop'
                    @stop = route.get('stop')
                    @render()
            app.request 'handlePublicTransitStopArrivals', @stop
        serializeData: ->
            thisStop = @stop
            thisStop.className = typeToName[thisStop.vehicleType]
            stoptimesWithoutPatterns = thisStop.stoptimesWithoutPatterns
            if stoptimesWithoutPatterns
                for stoptime in stoptimesWithoutPatterns
                    if stoptime.realtime
                        # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/component/DepartureListContainer.js#L18,L20
                        if stoptime.realtimeState != 'CANCELED'
                            # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/component/RouteScheduleContainer.js#L98
                            stoptime.arrivalTime = @formatTime((stoptime.serviceDay + stoptime.realtimeArrival) * 1000)
                    else
                        stoptime.arrivalTime = @formatTime((stoptime.serviceDay + stoptime.scheduledArrival) * 1000)
            stop: thisStop
        formatTime: (milliseconds) ->
            # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/component/DepartureTime.js#L72,L74
            moment(milliseconds).format('HH:mm')

    {PublicTransitStopView, PublicTransitStopsListView}
