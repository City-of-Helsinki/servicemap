define ['backbone.marionette', 'URI'], (Marionette, URI) ->

    class BaseRouter extends Backbone.Marionette.AppRouter
        initialize: (options) ->
            super options
            @controller = options.controller
            @makeMapView = options.makeMapView
            @appRoute /^\/?([^\/]*)$/, 'renderHome'
            @appRoute /^unit\/?([^\/]*)$/, 'renderUnit'
            @appRoute /^division\/?(.*?)$/, 'renderDivision'
            @appRoute /^address\/(.*?)$/, 'renderAddress'
            @appRoute /^search(\?[^\/]*)$/, 'renderSearch'
            @appRoute /^division(\?.*?)$/, 'renderMultipleDivisions'

        onPostRouteExecute: (context) ->
            if context?.query?.layer?
                app.commands.execute 'addDataLayer', context.query.layer

        executeRoute: (callback, args, context) ->
            callback?.apply(@, args)?.done (opts) =>
                mapOpts = {}
                if context.query?
                    mapOpts.bbox = context.query.bbox
                    mapOpts.level = context.query.level
                    if context.query.municipality?
                        mapOpts.fitAllUnits = true
                @makeMapView mapOpts
                opts?.afterMapInit?()
                @onPostRouteExecute context

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
            fullUri = new URI window.location.toString()
            unless args.length < 1 or lastArg == null
                newArgs = URI(lastArg).segment()
            else
                newArgs = []
            if fullUri.query()
                context.query = @processQuery fullUri.search(true)
                if context.query.map?
                    p13n.setMapBackgroundLayer context.query.map
                if context.query.city?
                    if window.isEmbedded == true
                        # We do not want the embeds to affect the users
                        # persistent settings
                        context.query.municipality = context.query.city
                    else
                        # For an entry through a link with a city
                        # shortcut, the p13n change should be permanent.
                        cities = context.query.city.split ','
                        p13n.setCities cities

                newArgs.push context
            @executeRoute callback, newArgs, context

        routeEmbedded: (uri) ->
            # An alternative implementation of 'static' routing
            # for browsers without pushState when creating
            # an embedded view.
            path = uri.segment()
            resource = path[0]
            callback = if resource == 'division'
                if 'ocd_id' of uri.search(true)
                    'renderMultipleDivisions'
                else
                    'renderDivision'
            else
                switch resource
                    when '' then 'renderHome'
                    when 'unit' then 'renderUnit'
                    when 'search' then 'renderSearch'
                    when 'address' then 'renderAddress'
            uri.segment 0, '' # remove resource from path
            relativeUri = new URI uri.pathname() + uri.search()
            callback = _.bind @controller[callback], @controller
            @execute callback, [relativeUri.toString()]
