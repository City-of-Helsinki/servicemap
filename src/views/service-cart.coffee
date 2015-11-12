define [
    'underscore',
    'cs!app/p13n',
    'cs!app/views/base',
], (
    _,
    p13n,
    base
)  ->

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
            'click input': 'selectLayerInput'
            'click label': 'selectLayerLabel'
            'click .data-layer a.toggle-layer': 'toggleDataLayer'
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
            data
        closeService: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        toggleDataLayer: (ev) ->
            app.commands.execute 'addDataLayer', 'popdensity:RTV201412'
        _selectLayer: (value) ->
            p13n.setMapBackgroundLayer value
        selectLayerInput: (ev) ->
            @_selectLayer $(ev.currentTarget).attr('value')
        selectLayerLabel: (ev) ->
            @_selectLayer $(ev.currentTarget).data('layer')
