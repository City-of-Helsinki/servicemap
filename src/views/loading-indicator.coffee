define (require) ->
    i18n                   = require 'i18next'
    {SMItemView, SMLayout} = require 'cs!app/views/base'

    class LoadingIndicatorView extends SMItemView
        className: 'loading-indicator'
        template: 'loading-indicator'
        initialize: ({@model}) ->
            @listenTo @model, 'change', @render
        serializeData: ->
            data = super()
            if data.status
                data.message = i18n.t "progress.#{data.status}"
            else
                data.message = ''
            data
        events:
            'click .cancel-button': 'onCancel'
        onCancel: (ev) ->
            ev.preventDefault()
            @model.cancel()
        onDomRefresh: ->
            if @model.get('complete') or @model.get('canceled')
                @$el.removeClass 'active'
            else
                @$el.addClass 'active'

    class SidebarLoadingIndicatorView extends SMLayout
        template: 'sidebar-loading-indicator'
        regions:
            indicator: '.loading-indicator-component'
        onDomRefresh: ->
            fn = =>
                @$el.find('.content').removeClass 'hidden'
                @trigger 'init'
            _.delay fn, 250
        initialize: ->
            @listenToOnce @, 'init', =>
                @indicator.show new LoadingIndicatorView model: @model

    {LoadingIndicatorView, SidebarLoadingIndicatorView}

