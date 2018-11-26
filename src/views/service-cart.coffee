define (require) ->
    _       = require 'underscore'

    p13n    = require 'cs!app/p13n'
    base    = require 'cs!app/views/base'

    class ServiceCartView extends base.SMItemView
        template: 'service-cart'
        tagName: 'ul'
        className: 'expanded container main-list'
        events: ->
            'click .maximizer': 'maximize'
            'keydown .maximizer': @keyboardHandler @maximize, ['space', 'enter']
            'click .cart-close-button': 'minimize'
            'click .remove-service': 'removeServiceItem'
            'keydown .remove-service': @keyboardHandler @removeServiceItem, ['space', 'enter']
            'click .map-layer input': 'selectLayerInput'
            'click .map-layer label': 'selectLayerLabel'
            # 'click .data-layer a.toggle-layer': 'toggleDataLayer'
            #'click .data-layer label': 'selectDataLayerLabel'
            'click .data-layer-heatmap input': (ev) -> @selectDataLayerInput('heatmap_layer', $(ev.currentTarget).prop('value'))
            'click .data-layer-statistics input': @selectStatisticsLayerInput

        initialize: ({@serviceNodes, @services, @selectedDataLayers}) ->
            for collection in [@serviceNodes, @services]
                @listenTo collection, 'add', @minimize
                @listenTo collection, 'remove', =>
                    if collection.length
                        @render()
                    else
                        @minimize()
                @listenTo collection, 'reset', @render

            @listenTo p13n, 'change', (path, value) =>
                if path[0] == 'map_background_layer' then @render()
            @listenTo @selectedDataLayers, 'change', @render

            @listenTo app.vent, 'statisticsDomainMax', (max) ->
                @statisticsDomainMax = max
                @render()

            @minimized = !@hasServiceItems()

        maximize: ->
            @minimized = false
            @render()

        minimize: ->
            @minimized = true
            @render()

        hasServiceItems: ->
            @serviceNodes.length + @services.length > 0

        onDomRefresh: ->
            if @hasServiceItems()
                @$el.addClass('has-services')
            else
                @$el.removeClass('has-services')

            if @minimized
                @$el.removeClass 'expanded'
                @$el.parent().removeClass 'expanded'
                @$el.addClass 'minimized'
            else
                @$el.addClass 'expanded'
                @$el.parent().addClass 'expanded'
                @$el.removeClass 'minimized'
                _.defer =>
                    @$el.find('input:checked').first().focus()

        serializeData: ->
            data = super()

            data.items = [].concat(
                @services.toJSON().map((item) =>
                    item.type = 'service'
                    item.color = item.root_service_node or models.Service.defaultRootColor
                    return item),
                @serviceNodes.toJSON().map((item) =>
                    item.type = 'serviceNode'
                    item.color = item.root or models.Service.defaultRootColor
                    return item)
            )

            data.minimized = @minimized
            data.layers = p13n.getMapBackgroundLayers()
            data.selectedLayer = p13n.get('map_background_layer')
            data.heatmapLayers = p13n.getHeatmapLayers().map (layerPath) =>
                layerPath.selected = @selectedDataLayers.get('heatmap_layer') == layerPath?.name
                layerPath
            data.statisticsLayers = p13n.getStatisticsLayers().map (layerPath) =>
                {
                    type: if layerPath?.name then layerPath.name.split('.')[0] else null
                    name: if layerPath?.name then layerPath.name.split('.')[1] else null
                    selected: @selectedDataLayers.get('statistics_layer') == layerPath?.name
                }
            data.selectedHeatmapLayer = @selectedDataLayers.get('heatmap_layer') || null
            selectedStatisticsLayer = @selectedDataLayers.get('statistics_layer')
            [type, name] = if selectedStatisticsLayer then selectedStatisticsLayer.split('.') else [null, null]
            data.selectedStatisticsLayer =
                type: type
                name: name
                max: type && @statisticsDomainMax
            data

        removeServiceItem: (event) ->
            $target = $(event.currentTarget)
            type = $target.data('type')
            id = $target.data('service')

            if type == 'service'
                app.request 'removeService', id
            else
                app.request 'removeServiceNode', id

        _selectLayer: (value) ->
            p13n.setMapBackgroundLayer value

        selectLayerInput: (event) ->
            @_selectLayer $(event.currentTarget).attr('value')

        selectLayerLabel: (event) ->
            @_selectLayer $(event.currentTarget).data('layer')

        selectDataLayerInput: (dataLayer, value) ->
            app.request 'removeDataLayer', dataLayer
            unless value == 'null'
                app.request 'addDataLayer', dataLayer, value
            @render()

        selectStatisticsLayerInput: (event) ->
            value = $(event.currentTarget).prop('value')
            app.request 'removeDataLayer', 'statistics_layer'
            if value != 'null'
                app.request 'showDivisions', null, value
