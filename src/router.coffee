define ['backbone.marionette'], (Marionette) ->
    delayTime = 500
    class Router extends Marionette.AppRouter
        routes:
            '': 'rootRoute'
            'unit/:id': 'renderUnit',
            'unit/?*params': 'renderUnitsWithFilter'

        rootRoute: ->
            app.vent.trigger 'route:rootRoute'
            app.vent.trigger 'title-view:show'

        renderUnit: (id)->
            $('body').addClass 'invisible'
            delayed = ->
                app.vent.trigger 'unit:render-one', id
                app.vent.trigger 'title-view:hide'
            _.delay delayed, delayTime

        renderUnitsWithFilter: (params) ->
            $('body').addClass 'invisible'
            delayed = ->
                app.vent.trigger 'units:render-with-filter', params
                app.vent.trigger 'title-view:hide'
            _.delay delayed, delayTime

    Router
