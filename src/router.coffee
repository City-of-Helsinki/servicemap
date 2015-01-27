
define [
    'backbone.marionette',
    'spin'
], (
    Marionette,
    Spinner
) ->

    delayTime = 500
    spinner = undefined
    class Router extends Marionette.AppRouter
        routes:
            '': 'rootRoute'
            'unit/:id': 'renderUnit',
            'unit/?*params': 'renderUnitsWithFilter'

        initialize: ->
            @listenTo app.vent, 'embedded-map-loading-indicator:hide', @removeLoadingIndicator

        rootRoute: ->
            app.vent.trigger 'route:rootRoute'
            app.vent.trigger 'title-view:show'

        renderUnit: (id)->
            @indicateLoading()
            delayed = ->
                app.vent.trigger 'unit:render-one', id
                app.vent.trigger 'title-view:hide'
            _.delay delayed, delayTime

        renderUnitsWithFilter: (params) ->
            @indicateLoading()
            delayed = ->
                app.vent.trigger 'units:render-with-filter', params
                app.vent.trigger 'title-view:hide'
            _.delay delayed, delayTime

        indicateLoading: ->
            $('#app-container').addClass 'invisible'
            spinner = new Spinner().spin(document.body)

        removeLoadingIndicator: ->
            $('#app-container').removeClass 'invisible'
            spinner.stop()

    Router
