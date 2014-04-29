define ['backbone.marionette'], (Marionette) ->
    delayTime = 500
    class Router extends Marionette.AppRouter
        routes:
            '': 'rootRoute'
            'unit/:id': 'renderUnit',
            'unit/?*params': 'renderUnitsWithFilter'

        rootRoute: ->
            app.vent.trigger 'route:rootRoute'

        renderUnit: (id)->
            delayed = -> app.vent.trigger 'unit:render-one', id
            _.delay delayed, delayTime

        renderUnitsWithFilter: (params) ->
            delayed = -> app.vent.trigger 'units:render-with-filter', params
            _.delay delayed, delayTime

    Router
