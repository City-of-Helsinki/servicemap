define (require) ->
    {SMItemView, SMLayout} = require 'cs!app/views/base'

    class LoadingIndicatorView extends SMItemView
        className: 'loading-indicator'
        template: 'loading-indicator'
        initialize: ({@model}) ->
            @listenTo @model, 'change', @render
        events:
            'click .cancel-button': 'onCancel'
        onCancel: (ev) ->
            ev.preventDefault()
            @model.cancel()
        render: ->
            super()
        onRender: ->
            if @model.get('complete') or @model.get('canceled')
                @$el.removeClass 'active'
            else
                @$el.addClass 'active'

    class SidebarLoadingIndicatorView extends SMLayout
        template: 'sidebar-loading-indicator'
        regions:
            indicator: '.loading-indicator-component'
        onRender: ->
            fn = =>
                @$el.find('.content').removeClass 'hidden'
            _.delay fn, 250
            @indicator.show new LoadingIndicatorView model: @model

    {LoadingIndicatorView, SidebarLoadingIndicatorView}

