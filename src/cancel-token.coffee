define (require) ->
    Backbone = require 'backbone'

    class CancelToken extends Backbone.Model
        initialize: ->
            @handlers = []
            @set 'active', false
            @set 'canceled', false
            @local = false
        addHandler: (fn) ->
            @handlers.push fn
        activate: (opts) ->
            if opts?.local then @local = true
            @set 'active', true, opts
        cancel: ->
            for fn in @handlers
                fn()
            @set 'canceled', true
            @set 'status', 'canceled'
            @trigger 'canceled'
            undefined
        complete: ->
            @set 'active', false
            @set 'complete', true
