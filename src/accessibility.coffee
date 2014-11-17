"use strict"

define ['underscore', 'backbone', 'app/models'], (_, Backbone, models) ->
    class Accessibility
        constructor: ->
            _.extend @, Backbone.Events
            #setTimeout @_request_data, 3000
            @_request_data()

        _request_data: =>
            settings =
                url: "#{app_settings.service_map_backend}/accessibility_rule/"
                success: (data) =>
                    @rules = data.rules
                    @messages = data.messages
                    @trigger 'change'
                error: (data) =>
                    throw new Error "Unable to retrieve accessibility data"
            Backbone.ajax settings
        _emit_shortcoming: (rule, messages) ->
            if rule.msg == null or rule.msg not of @messages
                return
            msg = @messages[rule.msg]
            if msg?
                segment = rule.path[0]
                unless segment of messages
                    messages[segment] = []
                segment_messages = messages[segment]
                requirement_id = rule.requirement_id
                unless requirement_id of segment_messages
                    segment_messages[requirement_id] = []
                current_messages = segment_messages[requirement_id]
                if rule.id == requirement_id
                    # This is a top level requirement -
                    # only add top level message
                    # if there are no specific messages.
                    unless current_messages.length
                        current_messages.push msg
                else
                    current_messages.push msg
            return

        _calculate_shortcomings: (rule, properties, messages, level=None) ->
            if rule.operands[0] not instanceof Object
                op = rule.operands
                prop = properties[op[0]]
                # If the information is not supplied, pretend that everything
                # is fine.
                if not prop
                    return true
                val = op[1]
                if rule.operator == 'NEQ'
                    is_okay = prop != val
                else if rule.operator == 'EQ'
                    is_okay = prop == val
                else
                    throw new Error "invalid operator #{rule.operator}"
                if not is_okay
                    @_emit_shortcoming rule, messages
                return is_okay

            ret_values = []
            for op in rule.operands
                is_okay = @_calculate_shortcomings op, properties, messages, level=level+1
                ret_values.push is_okay

            if rule.operator not in ['AND', 'OR']
                throw new Error "invalid operator #{rule.operator}"
            if rule.operator == 'AND' and false not in ret_values
                return true
            if rule.operator == 'OR' and true in ret_values
                return true

            @_emit_shortcoming rule, messages
            return false

        get_shortcomings: (properties, profile) ->
            if not @rules?
                return status: 'pending'
            prop_by_id = {}
            for p in properties
                prop_by_id[p.variable] = p.value
            messages = {}
            rule = @rules[profile]
            level = 0
            @_calculate_shortcomings rule, prop_by_id, messages, level=level
            status: 'complete'
            messages: messages

    return new Accessibility
