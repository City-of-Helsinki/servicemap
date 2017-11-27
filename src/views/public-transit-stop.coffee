define (require) ->
    base = require 'cs!app/views/base'

    class PublicTransitStopView extends base.SMItemView
        template: 'public-transit-stop'
        # regions:
        #     'arrivals': '.arrivals'
        initialize: ({@stop}) ->
            _.extend @stop, Backbone.Events
            @listenTo @stop, 'change', @drawArrivals
        # serializeData: ->
        #     stop: @stop
        #     @requestRoute()
        onRender: ->
            app.request 'handlePublicTransitStopArrivals', @stop
        drawArrivals: (data) ->
            $arrivalsEl = @$el.find('.arrivals')
            $arrivalsEl.append("<span>#{data.name}</span>")

    PublicTransitStopView
