define (require) ->
    Marionette   = require 'backbone.marionette'
    $            = require 'jquery'

    models       = require 'cs!app/models'
    Spinner      = require 'cs!app/spinner'
    TitleBarView = require 'cs!app/embedded-views'

    PAGE_SIZE = 1000
    delayTime = 1000
    spinner = new Spinner
        container: document.body
    #TODO enable title bar and loading spinner
    class Router extends Marionette.AppRouter
        execute: (callback, args) ->
            _.delay @indicateLoading, delayTime
            model = callback.apply(@, args)
            @listenTo model, 'sync', @removeLoadingIndicator
            @listenTo model, 'finished', @removeLoadingIndicator

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

        # renderUnitsWithFilter: (params) ->
        #     @listenToOnce @appState.units, 'finished', =>
        #         @drawUnits @appState.units
        #     units =  @appState.units
        #     params = @_parseParameters params
        #     key = 'division'
        #     divIds = params.divisions
            if _(params).has 'titlebar' # TODO enable
                app.getRegion('navigation').show new TitleBarView @appState.divisions
            # @_fetchDivisions divIds
            # units

        indicateLoading: ->
            spinner.start()

        removeLoadingIndicator: ->
            spinner?.stop()

    Router
