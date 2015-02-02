
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
            'embed/area/?*params': 'renderArea'

        execute: (callback, args) ->
            _.delay @indicateLoading, delayTime
            model = callback.apply(@, args)
            @listenTo model, 'sync', @removeLoadingIndicator
            @listenTo model, 'finished', @removeLoadingIndicator

        draw_units: (units, opts) =>
            @map_view.draw_units units, opts or zoom: true

        initialize: (@app, @app_state, @map_view) ->

        _fetchDivisions: (division_ids) ->
            @app_state.divisions
                .setFilter 'ocd_id', division_ids
                .setFilter 'geometry', true
                .fetch()

        _parse_parameters: (params) ->
            parsed_params = {}
            _(params.split '&').each (query) =>
                [k, v] = query.split('=', 2)
                if v.match /,/
                    v = v.split(',')
                else
                    v = [v]
                parsed_params[k] = v
            parsed_params

        renderUnit: (id)->
            unit = new models.Unit id: id
            @app_state.units = new models.UnitList [unit]
            @listenToOnce unit, 'sync', => @draw_units @app_state.units
            unit.fetch()
            unit

        renderUnitsWithFilter: (params) ->
            @listenToOnce @app_state.units, 'sync', @draw_units
            units =  @app_state.units
            params = @_parse_parameters params
            key = 'division'
            div_ids = params.divisions
            if _(params).has 'titlebar'
                app.getRegion('navigation').show new TitleBarView @app_state.divisions
            @_fetchDivisions div_ids
            units
                .setFilter key, div_ids.join(',')
                .fetch()
            units

        renderDivisions: (params) =>
            @listenToOnce @app_state.divisions, 'sync', => @map_view.fit_divisions(@app_state.divisions)
            [key, div_ids] = @_parse_division_params params.split('&')[0]
            @_fetchDivisions div_ids
            @app_state.divisions

        renderArea: (params) =>
            @listenTo @app_state.units, 'finished', => @draw_units @app_state.units, zoom: false
            params = @_parse_parameters params
            if _(params).has 'bbox'
                @map_view.fit_bbox params.bbox
            @app_state.units

        indicateLoading: ->
            spinner.start()

        removeLoadingIndicator: ->
            spinner?.stop()

    Router
