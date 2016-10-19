define (require) ->
    {SMItemView} = require 'cs!app/views/base'

    class NotificationLayout extends SMItemView
        # Used to show arbitrary messages to user
        template: 'notification-layout'
        className: 'notification-message'
        events: ->
            'click .notification-message__close' : 'close'
            'click .notification-message__content' : 'expand'
        modelEvents:
            'change': 'render'
        initialize: ->
            super()
            $('#map').one 'click', (e) -> console.log(e)
        serializeData: ->
            data = super()
            notificationTitle = @model.get 'notificationTitle'
            if !notificationTitle
                data.empty = true
            else
                data.notificationTitle = notificationTitle
                data.notificationMessage = @model.get 'notificationMessage'
                data.isCollapsed = !@model.get 'expand'
            data
        expand: ->
            if not @$el.hasClass('expanded')
                @$el.addClass 'expanded'
                @model.set 'expand', true
        close: ->
            @model.unset 'notificationTitle'
            @model.unset 'notificationMessage'
            @model.unset 'expand'
            @$el.removeClass 'expanded'
    NotificationLayout
