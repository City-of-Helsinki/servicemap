define ->

    class EventView extends base.SMLayout
        id: 'event-view-container'
        className: 'navigation-element'
        template: 'event'
        events:
            'click .back-button': 'go_back'
            'click .sp-name a': 'go_back'
        type: 'event'

        initialize: (options) ->
            @embedded = options.embedded
            @service_point = @model.get('unit')

        serializeData: ->
            data = @model.toJSON()
            data.embedded_mode = @embedded
            start_time = @model.get 'start_time'
            end_time = @model.get 'end_time'
            data.datetime = dateformat.humanize_event_datetime(
                start_time, end_time, 'large')
            if @service_point?
                data.sp_name = @service_point.get 'name'
                data.sp_url = @service_point.get 'www_url'
                data.sp_phone = @service_point.get 'phone'
            else
                data.sp_name = @model.get('location_extra_info')
                data.prevent_back = true
            data

        go_back: (event) ->
            event.preventDefault()
            app.commands.execute 'clearSelectedEvent'
            app.commands.execute 'selectUnit', @service_point
