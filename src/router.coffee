define ['backbone.marionette'], (Marionette) ->
    class Router extends Marionette.AppRouter
        routes:
            'unit/:id': 'renderUnit',
            'unit/?*params': 'renderUnitsWithFilter'

        renderUnit: (id)->
            app.vent.trigger 'unit:render-one', id

        renderUnitsWithFilter: (params) ->
            app.vent.trigger 'units:render-with-filter', params

    Router
