
define [
    'app/models',
    'backbone.marionette',
    'app/spinner',
    'jquery'
], (
    models,
    Marionette,
    Spinner,
    $
) ->

    delayTime = 1000
    spinner = new Spinner()

    class Router extends Marionette.AppRouter
        routes:
            'embed/unit/:id': 'renderUnit',
            'embed/unit/?*params': 'renderUnitsWithFilter'

        execute: (callback, args) ->
            _.delay @indicateLoading, delayTime
            callback.apply(@, args).done =>
                @removeLoadingIndicator()

        initialize: (@app_state, @map_view) ->
            @listenTo @app_state.units, 'reset', (units) =>
                @removeLoadingIndicator()
                @map_view.draw_units units, zoom: true

        renderUnit: (id)->
            ((def) =>
                unit = new models.Unit id: id
                unit.fetch
                    success: =>
                        @app_state.units.reset [unit]
                        def.resolve()
                    error: =>
                        def.resolve()
                        # TODO: decide where to route if route has invalid unit id.
                def) ($.Deferred())

        renderUnitsWithFilter: (params) ->
            delayed = ->
                app.vent.trigger 'units:render-with-filter', params
                app.vent.trigger 'title-view:hide'
            _.delay delayed, delayTime

        indicateLoading: ->
            #$('#app-container').addClass 'invisible'
            spinner.spin(document.body)

        removeLoadingIndicator: ->
            $('#app-container').removeClass 'invisible'
            spinner?.stop()

    Router
