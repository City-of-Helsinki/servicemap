define (require) ->
    _           = require 'underscore'
    URI         = require 'URI'
    Backbone    = require 'backbone'
    i18n        = require 'i18next'

    base        = require 'cs!app/views/base'
    ContextMenu = require 'cs!app/views/context-menu'
    p13n        = require 'cs!app/p13n'

    # TODO: rename to tool menu
    class ToolMenu extends base.SMLayout
        template: 'tool-menu'
        regions:
            toolContext: '#tool-context'
        events: ->
            'click': 'openMenu'
            'keydown #tool-context': @keyboardHandler @emptyToolContext, ['esc']
        openMenu: (ev) ->
            ev.preventDefault()
            ev.stopPropagation()
            if @toolContext.currentView?
                @emptyToolContext()
                return
            models = [
                # TODO: implement functionality
                # new Backbone.Model
                #     name: i18n.t 'tools.link_action'
                #     action: _.bind @linkAction, @
                #     icon: 'outbound-link'
                # new Backbone.Model
                #     name: i18n.t 'tools.share_action'
                #     action: _.bind @shareAction, @
                #     icon: 'outbound-link'
                new Backbone.Model
                    name: i18n.t 'tools.print_action'
                    action: _.bind @printAction, @
                    icon: 'map-options'
                new Backbone.Model
                    name: i18n.t 'tools.measure_action'
                    action: _.bind @measureAction, @
                    icon: 'measuring-tool'
                new Backbone.Model
                    name: i18n.t 'tools.export_action'
                    action: _.bind @exportAction, @
                    icon: 'outbound-link'
                new Backbone.Model
                    name: i18n.t 'tools.embed_action'
                    action: _.bind @embedAction, @
                    icon: 'outbound-link'
                new Backbone.Model
                    name: i18n.t 'tools.info_action'
                    action: _.bind @infoAction, @
                    icon: 'info'
            ]
            menu = new ContextMenu collection: new Backbone.Collection models
            @toolContext.show menu
            @$el.find('.sm-control-button').attr('aria-pressed', true)
            $(document).one 'click', (ev) =>
                @toolContext.empty()

        emptyToolContext: ->
            @toolContext.empty()
            @$el.find('.sm-control-button').attr('aria-pressed', false)

        printAction: (ev) ->
            app.request 'printMap'
        measureAction: (ev) ->
            app.request "activateMeasuringTool"
        linkAction: (ev) ->
            console.log 'link action clicked'
        shareAction: (ev) ->
            console.log 'share action clicked'
        embedAction: (ev) ->
            url = URI window.location.href
            directory = url.directory()
            directory = '/embedder' + directory
            url.directory directory
            url.port ''
            query = url.search true
            query.bbox = @getMapBoundsBbox()
            city = p13n.getCities()
            if city?
                query.city = city
            background = p13n.get('map_background_layer')
            if background not in ['servicemap', 'guidemap']
                query.map = background
            query.ratio = parseInt(100 * window.innerHeight / window.innerWidth)
            url.search query
            window.location.href = url.toString()
        exportAction: (ev) ->
            app.request 'showExportingView'
        feedbackAction: (ev) ->
            app.request 'composeFeedback', null
        infoAction: (ev) ->
            app.request 'showServiceMapDescription'
        getMapBoundsBbox: ->
            # TODO: don't break architecture thusly
            __you_shouldnt_access_me_like_this = window.mapView.map
            wrongBbox = __you_shouldnt_access_me_like_this._originalGetBounds().toBBoxString().split ','
            rightBbox = _.map [1,0,3,2], (i) -> wrongBbox[i].slice(0,8)
            rightBbox.join ','
        render: ->
            super()
            @el
