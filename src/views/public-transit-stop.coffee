define (require) ->
    base    = require 'cs!app/views/base'
    moment  = require 'moment'

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
            stoptimesWithoutPatterns = thisStop.stoptimesWithoutPatterns
            if stoptimesWithoutPatterns
                for stoptime in stoptimesWithoutPatterns
                    # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/component/RouteScheduleContainer.js#L98
                    stoptime.arrivalTime = moment((stoptime.serviceDay + stoptime.scheduledArrival) * 1000).format('HH:mm')
            stop: thisStop

    PublicTransitStopView
