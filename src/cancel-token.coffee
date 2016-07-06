define ->
    class CancelToken
        constructor: ->
            @handlers = []
        addHandler: (fn) ->
            @handlers.push fn
        cancel: ->
            for fn in @handlers
                fn()
            undefined
