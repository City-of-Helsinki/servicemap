
define [
    'app/models',
    'app/spinner',
    'app/embedded-views',
    'backbone.marionette',
    'jquery'
], (
    models,
    Spinner,
    TitleBarView
    Marionette,
    $
) ->

    PAGE_SIZE = 1000
    delayTime = 1000
    spinner = new Spinner
        container: document.body

    class Router extends Marionette.AppRouter
        routes:
            'embed/unit/:id': 'renderUnit',
            'embed/unit/?*params': 'renderUnitsWithFilter',
            'embed/position/?*params': 'renderPosition'

        execute: (callback, args) ->
            _.delay @indicateLoading, delayTime
            model = callback.apply(@, args)
            @listenTo model, 'sync', @removeLoadingIndicator

        draw_units: (units) =>
            @map_view.draw_units units, zoom: true

        initialize: (@app, @app_state, @map_view) ->

        renderUnit: (id)->
            unit = new models.Unit id: id
            @app_state.units = new models.UnitList [unit]
            @listenToOnce unit, 'sync', => @draw_units @app_state.units
            unit.fetch()
            unit

        renderUnitsWithFilter: (params) ->
            @listenToOnce @app_state.units, 'sync', @draw_units
            [units, divisions] =  [@app_state.units, @app_state.divisions]
            queries = params.split '&'
            [key, div_ids] = queries[0].split '=', 2
            if _.contains queries, 'titlebar'
                app.getRegion('navigation').show new TitleBarView @app_state.divisions
            units
                .setFilter key, div_ids
                .fetch()
            divisions
                .setFilter 'ocd_id', div_ids
                .setFilter 'geometry', true
                .fetch()
            units

        indicateLoading: ->
            #$('#app-container').addClass 'invisible'
            spinner.start()

        removeLoadingIndicator: ->
            $('#app-container').removeClass 'invisible'
            spinner?.stop()

    Router
