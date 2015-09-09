define [
    'backbone'
], (
    Backbone
) ->

    debugVariables = [
        'units',
        'services',
        'selectedUnits',
        'selectedEvents',
        'searchResults',
        'searchState'
    ]
    debugEvents = [
        'all'
    ]

    # Class whose name stands out in console output.
    class STATEFUL_EVENT

    class EventDebugger
        constructor: (@appControl) ->
            _.extend @, Backbone.Events
            @addListeners()

        addListeners: ->
            interceptor = (variableName) ->
                (eventName, target, rest...) ->
                    data = new STATEFUL_EVENT
                    data.variable = variableName
                    data.event = eventName
                    data.target = target?.toJSON?() or target
                    for param, i in rest
                        data["param_#{i+1}"] = param
                    console.log data
            for variableName in debugVariables
                for eventSpec in debugEvents
                    @listenTo @appControl[variableName], eventSpec,
                        interceptor(variableName)

    exports =
        EventDebugger: EventDebugger
        log: (x) -> console.log x
