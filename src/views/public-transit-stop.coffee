define (require) ->
    base    = require 'cs!app/views/base'
    moment  = require 'moment'

    class PublicTransitStopView extends base.SMItemView
        template: 'public-transit-stop'
        initialize: (opts) ->
            @stop = opts.stop
            @listenTo opts.route, 'change:stop', (route) ->
                if route.has 'stop'
                    @stop = route.get('stop')
                    @render()
            app.request 'handlePublicTransitStopArrivals', @stop
        serializeData: ->
            thisStop = @stop
            stoptimesWithoutPatterns = thisStop.stoptimesWithoutPatterns
            if stoptimesWithoutPatterns
                for stoptime in stoptimesWithoutPatterns
                    stoptime.arrival = moment((stoptime.serviceDay + stoptime.scheduledArrival) * 1000).format('HH:mm')
            stop: thisStop

    PublicTransitStopView
