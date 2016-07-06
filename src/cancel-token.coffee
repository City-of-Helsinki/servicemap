define (require) ->
    Backbone = require 'backbone'

    class CancelToken extends Backbone.Model
        initialize: ->
            @handlers = []
            @active = false
            @set 'canceled', false
        addHandler: (fn) ->
            @handlers.push fn
        activate: ->
            @active = true
        cancel: ->
            console.trace()
            for fn in @handlers
                fn()
            @set 'canceled', true
            undefined
