
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

        drawUnits: (units, opts) =>
            @mapView.drawUnits units, opts or zoom: true

        initialize: (@app, @appState, @mapView) ->

        _fetchDivisions: (divisionIds) ->
            @appState.divisions
                .setFilter 'ocd_id', divisionIds.join(',')
                .setFilter 'geometry', true
                .fetch()

        _parseParameters: (params) ->
            parsedParams = {}
            _(params.split '&').each (query) =>
                [k, v] = query.split('=', 2)
                if v.match /,/
                    v = v.split(',')
                else
                    v = [v]
                parsedParams[k] = v
            parsedParams

        renderUnit: (id)->
            unit = new models.Unit id: id
            @appState.units = new models.UnitList [unit]
            @listenToOnce unit, 'sync', => @drawUnits @appState.units
            unit.fetch()
            unit

        renderUnitsWithFilter: (params) ->
            @listenToOnce @appState.units, 'finished', =>
                @drawUnits @appState.units
            units =  @appState.units
            params = @_parseParameters params
            key = 'division'
            divIds = params.divisions
            if _(params).has 'titlebar'
                app.getRegion('navigation').show new TitleBarView @appState.divisions
            @_fetchDivisions divIds
            opts = success: =>
                unless units.fetchNext opts
                    units.trigger 'finished'
            units
                .setFilter key, divIds.join(',')
                .setFilter 'only', ['root_services', 'location', 'name'].join(',')
                .fetch opts
            units

        renderDivisions: (params) =>
            @listenToOnce @appState.divisions, 'sync', => @mapView.fitDivisions(@appState.divisions)
            [key, divIds] = @_parseDivisionParams params.split('&')[0]
            @_fetchDivisions divIds
            @appState.divisions

        renderArea: (params) =>
            @listenTo @appState.units, 'finished', => @drawUnits @appState.units, zoom: false
            params = @_parseParameters params
            if _(params).has 'bbox'
                @mapView.fitBbox params.bbox
            @appState.units

        indicateLoading: ->
            spinner.start()

        removeLoadingIndicator: ->
            spinner?.stop()

    Router
