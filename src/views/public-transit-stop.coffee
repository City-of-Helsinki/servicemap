define (require) ->
    base = require 'cs!app/views/base'

    class PublicTransitStopView extends base.SMItemView
        template: 'public-transit-stop'
        # regions:
        #     'arrivals': '.arrivals'
        initialize: (opts) ->
            @stop = opts.stop
            _.extend @stop, Backbone.Events
            @listenTo opts.route, 'change:stop', (route) ->
                if route.has 'stop'
                    stop = route.get('stop')
                    @drawArrivals stop
        # serializeData: ->
        #     stop: @stop
        #     @requestRoute()
        onRender: ->
            app.request 'handlePublicTransitStopArrivals', @stop
        drawArrivals: (data) ->
            $arrivalsEl = @$el.find('.arrivals')
            $arrivalsEl.append("<span>#{data.stoptimesWithoutPatterns[0].scheduledArrival}</span>")

    PublicTransitStopView
