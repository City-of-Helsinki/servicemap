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

    getIeVersion: () ->
        isInternetExplorer = ->
            window.navigator.appName is "Microsoft Internet Explorer"

        if not isInternetExplorer()
            return false

        matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
        return parseInt matches[1]
