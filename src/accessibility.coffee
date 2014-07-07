"use strict"

define ['underscore', 'backbone', 'app/models'], (_, Backbone, models) ->
    class Accessibility
        constructor: ->
            settings =
                url: "#{sm_settings.backend_url}/accessibility_rule/"
                success: (data) =>
                    @rules = data.rules
                    @messages = data.messages
                error: (data) =>
                    throw "Unable to retrieve accessibility data"

            Backbone.ajax settings

        _emit_shortcoming: (rule, messages) ->
            if rule.id not of @messages
                return
            msg = @messages[rule.id]
            if 'shortcoming' of msg
                messages.append msg.shortcoming
                console.log msg.shortcoming.fi
            return

        _calculate_shortcomings: (rule, properties, messages) ->
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
                    throw "invalid operator #{rule.operator}"
                if not is_okay
                    @_emit_shortcoming rule, messages
                return is_okay

            ret_values = []
            for op in rule.operands
                is_okay = @_calculate_shortcomings op, properties, messages
                ret_values.push is_okay

            if rule.operator not in ['AND', 'OR']
                throw "invalid operator #{rule.operator}"
            if rule.operator == 'AND' and false not in ret_values
                return true
            if rule.operator == 'OR' and true in ret_values
                return true

            @_emit_shortcoming rule, messages
            return false

        get_shortcomings: (properties, profile) ->
            prop_by_id = {}
            for p in properties
                prop_by_id[p.variable] = p.value

            first_rule = @rules[profile]
            messages = []
            @_calculate_shortcomings first_rule, prop_by_id, messages
            return messages

    return new Accessibility
