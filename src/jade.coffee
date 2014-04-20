define 'app/jade', ['underscore', 'jquery', 'i18next'], (_, $, i18n) ->
    # Make sure jade runtime is loaded
    if typeof jade != 'object'
        raise "Jade not loaded before app"

    class Jade
        get_template: (name) ->
            key = "views/templates/#{name}"
            if key not of JST
                throw "template #{name} not loaded"
            template_func = JST[key]
            return template_func

        template: (name, locals) ->
            if locals?
                if typeof locals != 'object'
                    throw "template must get an object argument"
            else
                locals = {}
            func = @get_template name
            data = _.clone locals
            data.t = i18n.t
            template_str = func data
            return $.trim template_str

    return new Jade
