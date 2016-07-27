define (require) ->
    Backbone = require 'backbone'

    class CancelToken extends Backbone.Model
        initialize: ->
            @handlers = []
            @set 'active', false
            @set 'canceled', false
        addHandler: (fn) ->
            @handlers.push fn
        activate: ->
            @set 'active', true
        cancel: ->
            console.trace()
            for fn in @handlers
                fn()
            @set 'canceled', true
            @trigger 'canceled'
            undefined
