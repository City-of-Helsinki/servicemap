define [
    'backbone'
], (
    Backbone
) ->

    debug_variables = [
        'units',
        'services',
        'selected_units',
        'selected_events',
        'search_results',
        'search_state'
    ]
    debug_events = [
        'all'
    ]

    # Class whose name stands out in console output.
    class STATEFUL_EVENT

    class EventDebugger
        constructor: (@app_control) ->
            _.extend @, Backbone.Events
            @add_listeners()

        add_listeners: ->
            interceptor = (variable_name) ->
                (event_name, target, rest...) ->
                    data = new STATEFUL_EVENT
                    data.variable = variable_name
                    data.event = event_name
                    data.target = target?.toJSON()
                    for param, i in rest
                        data["param_#{i+1}"] = param
                    console.log data
            for variable_name in debug_variables
                for event_spec in debug_events
                    @listenTo @app_control[variable_name], event_spec,
                        interceptor(variable_name)

    exports =
        EventDebugger: EventDebugger
