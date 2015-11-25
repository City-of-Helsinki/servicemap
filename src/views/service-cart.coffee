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
            'keydown .personalisation-container .maximizer': @keyboardHandler @maximize, ['space', 'enter']
            'click .button.cart-close-button': 'minimize'
            'click .button.close-button': 'closeService'
            'keydown .button.close-button': @keyboardHandler @closeService, ['space', 'enter']
            'click input': 'selectLayerInput'
            'click label': 'selectLayerLabel'
        initialize: (opts) ->
            @collection = opts.collection
            @listenTo @collection, 'add', @maximize
            @listenTo @collection, 'remove', =>
                if @collection.length
                    @render()
                else
                    @minimize()
            @listenTo @collection, 'reset', @render
            @listenTo @collection, 'minmax', @render
            @listenTo p13n, 'change', (path, value) =>
                if path[0] == 'map_background_layer' then @render()
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
            if @minimized
                @$el.removeClass 'expanded'
                @$el.addClass 'minimized'
            else
                @$el.addClass 'expanded'
                @$el.removeClass 'minimized'
                _.defer =>
                    @$el.find('input:checked').first().focus()
        serializeData: ->
            if @minimized
                return minimized: true
            data = super()
            data.layers = p13n.getMapBackgroundLayers()
            data
        closeService: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        _selectLayer: (value) ->
            p13n.setMapBackgroundLayer value
        selectLayerInput: (ev) ->
            @_selectLayer $(ev.currentTarget).attr('value')
        selectLayerLabel: (ev) ->
            @_selectLayer $(ev.currentTarget).data('layer')
