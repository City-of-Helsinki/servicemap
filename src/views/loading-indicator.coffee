define (require) ->
    {SMItemView, SMLayout} = require 'cs!app/views/base'

    class LoadingIndicatorView extends SMItemView
        className: 'loading-indicator'
        template: 'loading-indicator'
        events:
            'click .cancel-button': 'onCancel'
        onCancel: (ev) ->
            ev.preventDefault()
            @model.cancel()


    class SidebarLoadingIndicatorView extends SMLayout
        template: 'sidebar-loading-indicator'
        regions:
            indicator: '.loading-indicator-component'
        initialize: ->
            @listenTo @model, 'change', @render
        onRender: ->
            @indicator.show new LoadingIndicatorView model: @model

    {LoadingIndicatorView, SidebarLoadingIndicatorView}

