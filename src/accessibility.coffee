"use strict"

define [
    'underscore',
    'backbone',
    'app/models'
], (
    _,
    Backbone,
    models
) ->

    class Accessibility
        constructor: ->
            _.extend @, Backbone.Events
            #setTimeout @_requestData, 3000
            @_requestData()

        _requestData: =>
            settings =
                url: "#{appSettings.service_map_backend}/accessibility_rule/"
                success: (data) =>
                    @rules = data.rules
                    @messages = data.messages
                    @trigger 'change'
                error: (data) =>
                    throw new Error "Unable to retrieve accessibility data"
            Backbone.ajax settings
        _emitShortcoming: (rule, messages) ->
            if rule.msg == null or rule.msg not of @messages
                return
            msg = @messages[rule.msg]
            if msg?
                segment = rule.path[0]
                unless segment of messages
                    messages[segment] = []
                segmentMessages = messages[segment]
                requirementId = rule.requirement_id
                unless requirementId of segmentMessages
                    segmentMessages[requirementId] = []
                currentMessages = segmentMessages[requirementId]
                if rule.id == requirementId
                    # This is a top level requirement -
                    # only add top level message
                    # if there are no specific messages.
                    unless currentMessages.length
                        currentMessages.push msg
                else
                    currentMessages.push msg
            return

        _calculateShortcomings: (rule, properties, messages, level=None) ->
            if rule.operands[0] not instanceof Object
                op = rule.operands
                prop = properties[op[0]]
                # If the information is not supplied, pretend that everything
                # is fine.
                if not prop
                    return true
                val = op[1]
                if rule.operator == 'NEQ'
                    isOkay = prop != val
                else if rule.operator == 'EQ'
                    isOkay = prop == val
                else
                    throw new Error "invalid operator #{rule.operator}"
                if not isOkay
                    @_emitShortcoming rule, messages
                return isOkay

            retValues = []
            for op in rule.operands
                isOkay = @_calculateShortcomings op, properties, messages, level=level+1
                retValues.push isOkay

            if rule.operator not in ['AND', 'OR']
                throw new Error "invalid operator #{rule.operator}"
            if rule.operator == 'AND' and false not in retValues
                return true
            if rule.operator == 'OR' and true in retValues
                return true

            @_emitShortcoming rule, messages
            return false

        getShortcomings: (properties, profile) ->
            if not @rules?
                return status: 'pending'
            propById = {}
            for p in properties
                propById[p.variable] = p.value
            messages = {}
            rule = @rules[profile]
            level = 0
            @_calculateShortcomings rule, propById, messages, level=level
            status: 'complete'
            messages: messages

    return new Accessibility
