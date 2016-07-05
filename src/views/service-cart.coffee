define (require) ->
    _       = require 'underscore'
    p13n    = require 'cs!app/p13n'
    base    = require 'cs!app/views/base'
    dataviz = require 'cs!app/data-visualization'

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
            'click .data-layer input': 'selectDataLayerInput'

        initialize: (opts) ->
            @collection = opts.collection
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
            @minimized = false
            if @collection.length
                @minimized = false
            else
                @minimized = true
        maximize: ->
            @minimized = false
            @collection.trigger 'minmax'
        minimize: ->
            @minimized = true
            @collection.trigger 'minmax'
        onRender: ->
            if @collection.length
                @$el.addClass('has-services')
            else
                @$el.removeClass('has-services')
            if @minimized
                @$el.removeClass 'expanded'
                @$el.addClass 'minimized'
            else
                @$el.addClass 'expanded'
                @$el.removeClass 'minimized'
                _.defer =>
                    @$el.find('input:checked').first().focus()
        serializeData: ->
            data = super()
            data.minimized = @minimized
            data.layers = p13n.getMapBackgroundLayers()
            data.selectedLayer = p13n.get('map_background_layer')
            data.dataLayers = p13n.getDataLayers()
            data.selectedDataLayer = p13n.get 'data_layer'
            # Should default to null
            unless data.selectedDataLayer
                data.selectedDataLayer = null
            data
        closeService: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        _selectLayer: (value) ->
            p13n.setMapBackgroundLayer value
        selectLayerInput: (ev) ->
            @_selectLayer $(ev.currentTarget).attr('value')
        selectLayerLabel: (ev) ->
            @_selectLayer $(ev.currentTarget).data('layer')
        selectDataLayerInput: (ev) ->
            value = $(ev.currentTarget).prop('value')
            app.commands.execute 'removeDataLayer', p13n.get 'data_layer'
            unless value == 'null'
                app.commands.execute 'addDataLayer', value
            @render()
