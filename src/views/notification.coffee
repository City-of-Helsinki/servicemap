define (require) ->
    {SMItemView} = require 'cs!app/views/base'

    # Used to show arbitrary messages to user.
    # Setting show: true for the model displays the notification and setting show: false
    # closes the notification.
    class NotificationLayout extends SMItemView
        # Used to show arbitrary messages to user
        template: 'notification-layout'
        className: 'notification-message'
        events: ->
            'click .notification-message__close' : 'onCloseClick'
            'click' : 'expand'
        modelEvents:
            'change': 'onChange'
            'change:show': 'showChanged'
            'change:expand': 'expandChanged'
        serializeData: ->
            data = super()
            notificationTitle = @model.get 'title'
            notificationMessage = @model.get 'message'
            if !notificationTitle and !notificationMessage
                data.empty = true
            else
                data.notificationTitle = notificationTitle
                data.notificationMessage = notificationMessage
                data.isCollapsed = !@model.get 'expand'
            data
        displayNotification: ->
            $('body').addClass 'notification-open'
            @$el.show();
        expand: ->
            @model.set 'expand', true
        close: ->
            @$el.modal 'hide'
            @$el.removeClass('expanded').hide()
            $('body').removeClass 'notification-open'
        onCloseClick: (e) ->
            @model.clear()
            e.stopPropagation()
            @close()
        onChange: ->
            if not @$el.hasClass('expanded')
                @$el.removeClass('modal').removeAttr 'style'
            @render()
        showChanged: (model, show) ->
            if show then @displayNotification() else @close()
        expandChanged: (model, expand) ->
            if expand
                @$el.addClass 'expanded'
                @$el.addClass('modal').modal 'show'
    NotificationLayout
