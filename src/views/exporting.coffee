define ['underscore', 'URI', 'backbone', 'app/views/base', 'app/views/context-menu', 'app/p13n', 'i18next'], (_, URI, Backbone, base, ContextMenu, p13n, i18n) ->

    class ExportingView extends base.SMLayout
        template: 'exporting'
        regions:
            exportingContext: '#exporting-context'
        events:
            'click': 'openMenu'
        openMenu: (ev) ->
            ev.preventDefault()
            ev.stopPropagation()
            if @exportingContext.currentView?
                @exportingContext.reset()
                return
            models = [
                new Backbone.Model
                    name: i18n.t 'tools.embed_action'
                    action: _.bind @exportEmbed, @
            ]
            menu = new ContextMenu collection: new Backbone.Collection models
            @exportingContext.show menu
            $(document).one 'click', (ev) =>
                @exportingContext.reset()
        exportEmbed: (ev) ->
            url = URI window.location.href
            directory = url.directory()
            directory = '/embedder' + directory
            url.directory directory
            query = url.search true
            query.bbox = @getMapBoundsBbox()
            background = p13n.get('map_background_layer')
            if background not in ['servicemap', 'guidemap']
                query.map = background
            query.ratio = parseInt(100 * window.innerHeight / window.innerWidth)
            url.search query
            window.location.href = url.toString()
        getMapBoundsBbox: ->
            # TODO: don't break architecture thusly
            __you_shouldnt_access_me_like_this = window.mapView.map
            wrongBbox = __you_shouldnt_access_me_like_this._originalGetBounds().toBBoxString().split ','
            rightBbox = _.map [1,0,3,2], (i) -> wrongBbox[i].slice(0,8)
            rightBbox.join ','
        render: ->
            super()
            @el
