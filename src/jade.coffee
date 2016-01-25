define [
    'underscore',
    'jquery',
    'i18next',
    'cs!app/p13n',
    'cs!app/dateformat'
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
        humanDateRange: (startTime, endTime) ->
            formatted = dateformat.humanizeEventDatetime(
                startTime, endTime, 'small', hasEndTime=false
            )
            return formatted.date
        humanDistance: (meters) ->
            return if meters == Number.MAX_VALUE
                "?"
            else if meters < 1000
                "#{Math.ceil meters }m"
            else
                val = Math.ceil(meters/100).toString()
                [a, b] = [val.slice(0, -1), val.slice(-1)]
                if b != "0"
                    "#{a}.#{b}km"
                else
                    "#{a}km"
        humanShortcomings: (count) ->
            return if count == Number.MAX_VALUE
                i18n.t 'accessibility.no_data'
            else if count == 0
                i18n.t 'accessibility.no_shortcomings'
            else
                i18n.t 'accessibility.shortcoming_count', count: count
        humanDate: (datetime) ->
            res = dateformat.humanizeSingleDatetime datetime
        uppercaseFirst: (val) ->
            val.charAt(0).toUpperCase() + val.slice 1
        parsePostalcode: (val) ->
            val.split('postinumero:')[1]

        externalLink: (href, name, attributes) ->
            data = href: href, name: name
            data.attributes = attributes or {}
            @template 'external-link', data

        mixinHelpers: (data) ->
            helpers = [
                ['t', i18n.t]
                ['tAttr', @tAttr]
                ['tAttrHasLang', @tAttrHasLang]
                ['phoneI18n', @phoneI18n]
                ['staticPath', @staticPath]
                ['humanDateRange', @humanDateRange]
                ['humanDate', @humanDate]
                ['humanDistance', @humanDistance]
                ['uppercaseFirst', @uppercaseFirst]
                ['parsePostalcode', @parsePostalcode]
                ['humanShortcomings', @humanShortcomings]
                ['pad', (s) => " #{s} "]
                ['externalLink', _.bind @externalLink, @]]

            for [name, method] in helpers
                setHelper data, name, method
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
