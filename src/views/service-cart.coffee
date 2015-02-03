define ->

    class ServiceCartView extends base.SMItemView
        template: 'service-cart'
        tagName: 'ul'
        className: 'expanded container'
        events:
            'click .personalisation-container .maximizer': 'maximize'
            'click .button.cart-close-button': 'minimize'
            'click .button.close-button': 'close_service'
            'click input.unselected': 'select_layer_input'
            'click label.unselected': 'select_layer_label'
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
        serializeData: ->
            if @minimized
                return minimized: true
            data = super()
            data.layers = p13n.get_map_background_layers()
            data
        close_service: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        other_layer: ->
            layer = _.find ['servicemap', 'guidemap'],
                (l) => l != p13n.get('map_background_layer')
        switch_map: (ev) ->
            p13n.set_map_background_layer @other_layer()
        _select_layer: (value) ->
            p13n.set_map_background_layer value
        select_layer_input: (ev) ->
            @_select_layer $(ev.currentTarget).attr('value')
        select_layer_label: (ev) ->
            @_select_layer $(ev.currentTarget).data('layer')
