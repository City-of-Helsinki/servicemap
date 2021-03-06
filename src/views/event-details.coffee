define (require) ->
    dateformat = require 'cs!app/dateformat'
    base       = require 'cs!app/views/base'

    class EventDetailsView extends base.SMLayout
        id: 'event-view-container'
        className: 'navigation-element'
        template: 'event'
        events:
            'click .back-button': 'goBack'
            'click .sp-name a': 'goBack'
        type: 'event'

        initialize: (options) ->
            @embedded = options.embedded
            @servicePoint = @model.get('unit')

        serializeData: ->
            data = @model.toJSON()
            data.embedded_mode = @embedded
            startTime = @model.get 'start_time'
            endTime = @model.get 'end_time'
            data.datetime = dateformat.humanizeEventDatetime(
                startTime, endTime, 'large')
            if @servicePoint?
                data.sp_name = @servicePoint.get 'name'
                data.sp_url = @servicePoint.get 'www_url'
                data.sp_phone = @servicePoint.get 'phone'
            else
                data.sp_name = @model.get('location_extra_info')
                data.prevent_back = true
            data

        goBack: (event) ->
            event.preventDefault()
            app.request 'clearSelectedEvent'
            app.request 'selectUnit', @servicePoint, {}
