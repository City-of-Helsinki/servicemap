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
            'hidden.bs.modal': 'clearModalStyling'
        modelEvents:
            'change': 'onChange'
            'change:show': 'showChanged'
            'change:expand': 'expandChanged'
        serializeData: ->
            data = super()
            notificationTitle = @model.get 'title'
            notificationMessage = @model.get 'message'
            data.show = @model.get 'show'
            data.notificationTitle = notificationTitle
            data.notificationMessage = notificationMessage
            data.isCollapsed = !@model.get 'expand'
            data
        displayNotification: ->
            @removeDelayedHideListener()
            $('body').addClass 'notification-open'
            view = @
            f = (e) ->
                if not($(e.target).is(view.$el) or view.$el.has(".#{e.target.className}").length)
                    $('body').off 'keydown click zoomstart', f
                    view.hideTimer = setTimeout () ->
                        view.model.set 'show', false
                    , 6000
            @delayedHideListener = f
            $('body').one 'keydown click zoomstart', f
        expand: ->
            @model.set 'expand', true
        close: ->
            $('body').removeClass 'notification-open'
            @model.unset 'expand'
            clearTimeout(@hideTimer)
        onCloseClick: (e) ->
            @model.clear()
            e.stopPropagation()
        onChange: (model) ->
            @render()
        showChanged: (model, show) ->
            if show then @displayNotification() else @close()
        expandChanged: (model, expand) ->
            if expand
                @removeDelayedHideListener()
                @$el.addClass 'expanded'
                @$el.addClass('modal').modal
                    keyboard: true
                    backdrop: 'static'
                    show: true
                $('.modal-backdrop').one 'click', () =>
                    @model.set 'show', false
            else
                @$el.removeClass 'expanded'
                @$el.modal 'hide'
        clearModalStyling: ->
            @$el.removeClass('modal').removeAttr 'style'

        removeDelayedHideListener: ->
            clearTimeout @hideTimer
            delete @hideTimer
            $('body').off 'keydown click zoomstart', @delayedHideListener

    NotificationLayout
