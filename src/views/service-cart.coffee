define (require) ->
    _       = require 'underscore'

    p13n    = require 'cs!app/p13n'
    base    = require 'cs!app/views/base'

    class ServiceCartView extends base.SMItemView
        template: 'service-cart'
        tagName: 'ul'
        className: 'expanded container main-list'
        events: ->
            'click .personalisation-container .maximizer': 'maximize'
            'click .services.maximizer': 'maximize'
            'keydown .personalisation-container .maximizer': @keyboardHandler @maximize, ['space', 'enter']
            'click .button.cart-close-button': 'minimize'
            'click .button.close-button': 'closeService'
            'keydown .button.close-button': @keyboardHandler @closeService, ['space', 'enter']
            'click .map-layer input': 'selectLayerInput'
            'click .map-layer label': 'selectLayerLabel'
            # 'click .data-layer a.toggle-layer': 'toggleDataLayer'
            #'click .data-layer label': 'selectDataLayerLabel'
            'click .data-layer-heatmap input': (ev) -> @selectDataLayerInput('heatmap_layer', $(ev.currentTarget).prop('value'))
            'click .data-layer-statistics input': @selectStatisticsLayerInput
            'click #public-transit-stops': @selectMobilityLayer

        initialize: ({@collection, @selectedDataLayers, @route}) ->
            @listenTo @collection, 'add', @minimize
            @listenTo @collection, 'remove', =>
                if @collection.length
                    @render()
                else
                    @minimize()
            @listenTo @collection, 'reset', @render
            @listenTo @collection, 'minmax', @render
            @listenTo p13n, 'change', (path, value) =>
                if path[0] == 'map_background_layer' then @render()
            @listenTo @selectedDataLayers, 'change', @render
            @listenTo app.vent, 'statisticsDomainMax', (max) ->
                @statisticsDomainMax = max
                @render()
            @listenTo @route, 'change:publicTransitStops', (route) ->
                previousValue = !!route.previous('publicTransitStops')
                newValue = route.has 'publicTransitStops'
                @handlePublicTransitStops previousValue, newValue
            @minimized = false
            if @collection.length
                @minimized = false
            else
                @minimized = true
        onRender: ->
            $('#data-layer-mobility').off('hidden.bs.collapse').on 'hidden.bs.collapse', =>
                @isMobilityLayerServiceCartShown = false
            $('#data-layer-mobility').off('shown.bs.collapse').on 'shown.bs.collapse', =>
                @isMobilityLayerServiceCartShown = true
        maximize: ->
            @minimized = false
            @collection.trigger 'minmax'
        minimize: ->
            @minimized = true
            @isMobilityLayerServiceCartShown = false
            @collection.trigger 'minmax'
        onDomRefresh: ->
            if @collection.length
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
            data.isMobilityLayerSelected = p13n.get('mobility_layer')
            data.hasPublicTransitStops = @route.has 'publicTransitStops'
            data.isMobilityLayerServiceCartShown = @isMobilityLayerServiceCartShown
            data
        closeService: (ev) ->
            app.request 'removeService', $(ev.currentTarget).data('service')
        _selectLayer: (value) ->
            p13n.setMapBackgroundLayer value
        selectLayerInput: (ev) ->
            @_selectLayer $(ev.currentTarget).attr('value')
        selectLayerLabel: (ev) ->
            @_selectLayer $(ev.currentTarget).data('layer')
        selectDataLayerInput: (dataLayer, value) ->
            app.request 'removeDataLayer', dataLayer
            unless value == 'null'
                app.request 'addDataLayer', dataLayer, value
            @render()
        selectStatisticsLayerInput: (ev) ->
            value = $(ev.currentTarget).prop('value')
            app.request 'removeDataLayer', 'statistics_layer'
            if value != 'null'
                app.request 'showDivisions', null, value
        selectMobilityLayer: ->
            app.request 'toggleMobilityLayer'
            @render()
        handlePublicTransitStops: (previousValue, newValue) ->
            if previousValue is not newValue
                @render()
