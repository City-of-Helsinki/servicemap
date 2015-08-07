define ['backbone.marionette', 'URI'], (Marionette, URI) ->

    class BaseRouter extends Backbone.Marionette.AppRouter
        initialize: (options) ->
            super options
            @controller = options.controller
            @makeMapView = options.makeMapView
            @appRoute /^\/?([^\/]*)$/, 'renderHome'
            @appRoute /^unit\/?([^\/]*)$/, 'renderUnit'
            @appRoute /^search(\?[^\/]*)$/, 'renderSearch'
            @appRoute /^division\/?(.*?)$/, 'renderDivision'
            @appRoute /^division(\?.*?)$/, 'renderMultipleDivisions'
            @appRoute /^address\/(.*?)$/, 'renderAddress'

        _parseUrlQuery: (path) ->
            if path.match /\?.*/
                keyValuePair = /([^=\/&?]+=[^=\/&?]+)/g
                keyValStrings = path.match keyValuePair
                _.object _(keyValStrings).map (s) => s.split '='
            else
                false

        onPostRouteExecute: ->
        executeRoute: (callback, args, context) ->
            callback?.apply(@, args)?.done (opts) =>
                mapOpts = {}
                if context.query?.bbox?
                    mapOpts.bbox = context.query.bbox
                @makeMapView mapOpts
                opts?.afterMapInit?()
                @onPostRouteExecute()

        processQuery: (q) ->
            if q.bbox? and q.bbox.match /([0-9]+\.?[0-9+],)+[0-9]+\.?[0-9+]/
                q.bbox = q.bbox.split ','
            if q.ocd_id? and q.ocd_id.match /([^,]+,)*[^,]+/
                q.ocdId = q.ocd_id.split ','
                delete q.ocd_id
            return q

        execute: (callback, args) ->
            # The map view must only be initialized once
            # the state encoded in the route URL has been
            # reconstructed. The state affects the map
            # centering, zoom, etc.o
            context = {}
            lastArg = args[args.length - 1]
            unless args.length < 1 or lastArg == null
                uri = new URI lastArg
                newArgs = uri.segment()
                if uri.query()
                    context.query = @processQuery uri.search(true)
                    newArgs.push context
            @executeRoute callback, newArgs, context
