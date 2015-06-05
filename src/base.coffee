define ->
    mixOf: (base, mixins...) ->
        class Mixed extends base
            for mixin in mixins by -1 # earlier mixins override later ones
                for name, method of mixin::
                    Mixed::[name] = method
            Mixed

    resolveImmediately: ->
        $.Deferred().resolve().promise()

    withDeferred: (callback) ->
        deferred = $.Deferred()
        callback deferred
        deferred.promise()

    pad: (number) ->
        str = "" + number
        pad = "00000"
        pad.substring(0, pad.length - str.length) + str
