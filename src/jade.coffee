define [
    'underscore',
    'jquery',
    'i18next',
    'app/p13n',
    'app/dateformat'
], (
    _,
    $,
    i18n,
    p13n,
    dateformat
) ->

    # Make sure jade runtime is loaded
    if typeof jade != 'object'
        throw new Error "Jade not loaded before app"

    setHelper = (data, name, helper) ->
        if name of data
            return
        data[name] = helper

    class Jade
        getTemplate: (name) ->
            key = "views/templates/#{name}"
            if key not of JST
                throw new Error "template '#{name}' not loaded"
            templateFunc = JST[key]
            return templateFunc

        tAttr: (attr) ->
            return p13n.getTranslatedAttr attr
        tAttrHasLang: (attr) ->
            if not attr
                return false
            return p13n.getLanguage() of attr
        phoneI18n: (num) ->
            if num.indexOf '0' == 0
                # FIXME: make configurable
                num = '+358' + num.substring 1
            num = num.replace /\s/g, ''
            num = num.replace /-/g, ''
            return num
        staticPath: (path) ->
            # Strip leading slash
            if path.indexOf('/') == 0
                path = path.substring 1
            return appSettings.static_path + path
        humanDate: (startTime, endTime) ->
            formatted = dateformat.humanizeEventDatetime(
                startTime, endTime, 'small', hasEndTime=false
            )
            return formatted.date
        humanDistance: (meters) ->
            if meters < 1000
                "#{Math.ceil meters }m"
            else
                val = Math.ceil(meters/100).toString()
                [a, b] = [val.slice(0, -1), val.slice(-1)]
                "#{a}.#{b}km"
        uppercaseFirst: (val) ->
            val.charAt(0).toUpperCase() + val.slice 1

        mixinHelpers: (data) ->
            setHelper data, 't', i18n.t
            setHelper data, 'tAttr', @tAttr
            setHelper data, 'tAttrHasLang', @tAttrHasLang
            setHelper data, 'phoneI18n', @phoneI18n
            setHelper data, 'staticPath', @staticPath
            setHelper data, 'humanDate', @humanDate
            setHelper data, 'humanDistance', @humanDistance
            setHelper data, 'uppercaseFirst', @uppercaseFirst
            setHelper data, 'pad', (s) => " #{s} "
            data

        template: (name, locals) ->
            if locals?
                if typeof locals != 'object'
                    throw new Error "template must get an object argument"
            else
                locals = {}
            func = @getTemplate name
            data = _.clone locals
            @mixinHelpers data
            templateStr = func data
            return $.trim templateStr

    return new Jade
