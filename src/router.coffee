define ['backbone.marionette'], (Marionette) ->
    class Router extends Marionette.AppRouter
        routes:
            'unit/:id': 'renderUnit'

        renderUnit: (id)->
            app.vent.trigger 'unit:render-one', id

    Router
