define 'app/jade', ['underscore', 'jquery', 'i18next'], (_, $, i18n) ->
    # Make sure jade runtime is loaded
    if typeof jade != 'object'
        raise "Jade not loaded before app"

    class Jade
        template: (name, locals) ->
            if locals?
                if typeof locals != 'object'
                    throw "template must get an object argument"
            else
                locals = {}
            key = "views/templates/#{name}"
            if not key of JST
                throw "template #{name} not loaded"
            func = JST[key]
            data = _.clone locals
            data.t = i18n.t
            return $.trim(func data)

    return new Jade
