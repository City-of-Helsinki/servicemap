define [
    'cs!app/dateformat',
    'cs!app/views/base',
], (
    dateformat,
    base,
) ->

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
            app.commands.execute 'clearSelectedEvent'
            app.commands.execute 'selectUnit', @servicePoint
