define (require) ->
    _        = require 'underscore'
    Backbone = require 'backbone'

    if appSettings.is_embedded
        return null

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
            """
            Return value: false: message was empty, not emitted
                          true: message was emitted
            """
            if rule.msg == null or rule.msg not of @messages
                return false
            msg = @messages[rule.msg]
            unless msg?
                return false

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
                    return true
            else
                currentMessages.push msg
                return true
            return true

        _calculateShortcomings: (rule, properties, messages, level=None) ->
            if rule.operands[0] not instanceof Object
                # This is a leaf rule.
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
                    messageWasEmitted = @_emitShortcoming rule, messages
                return [isOkay, messageWasEmitted]

            # This is a compound rule
            retValues = []
            deeper_level = level + 1
            for op in rule.operands
                [isOkay, messageWasEmitted] = @_calculateShortcomings op, properties, messages, level=deeper_level
                if rule.operator == 'AND' and not isOkay and not messageWasEmitted
                    # Short circuit AND evaluation when no message
                    # was emitted. This edge case is required!
                    return [false, false]
                retValues.push isOkay

            if rule.operator not in ['AND', 'OR']
                throw new Error "invalid operator #{rule.operator}"
            if rule.operator == 'AND' and false not in retValues
                return [true, false]
            if rule.operator == 'OR' and true in retValues
                return [true, false]

            messageWasEmitted = @_emitShortcoming rule, messages
            return [false, messageWasEmitted]

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

        getTranslatedShortcomings: (profiles, model) ->
            shortcomings = {}
            seen = {}
            for pid in _.keys profiles
                shortcoming = @getShortcomings model.get('accessibility_properties'), pid
                if shortcoming.status != 'complete'
                    return status: 'pending', results: {}
                if _.keys(shortcoming.messages).length
                    for segmentId, segmentMessages of shortcoming.messages
                        shortcomings[segmentId] = shortcomings[segmentId] or {}
                        for requirementId, messages of segmentMessages
                            gatheredMessages = []
                            for msg in messages
                                translated = p13n.getTranslatedAttr msg
                                if translated not of seen
                                    seen[translated] = true
                                    gatheredMessages.push msg
                            if gatheredMessages.length
                                shortcomings[segmentId][requirementId] = gatheredMessages
            status: 'success'
            results: shortcomings

    return new Accessibility
