define 'app/jade', ['underscore', 'jquery', 'i18next', 'app/p13n'], (_, $, i18n, p13n) ->
    # Make sure jade runtime is loaded
    if typeof jade != 'object'
        raise "Jade not loaded before app"

    class Jade
        get_template: (name) ->
            key = "views/templates/#{name}"
            if key not of JST
                throw "template '#{name}' not loaded"
            template_func = JST[key]
            return template_func

        t_attr: (attr) ->
            return p13n.get_translated_attr attr
        t_attr_has_lang: (attr) ->
            if not attr
                return false
            return p13n.get_language() of attr

        template: (name, locals) ->
            if locals?
                if typeof locals != 'object'
                    throw "template must get an object argument"
            else
                locals = {}
            func = @get_template name
            data = _.clone locals
            data.t = i18n.t
            data.t_attr = @t_attr
            data.t_attr_has_lang = @t_attr_has_lang
            template_str = func data
            return $.trim template_str

    return new Jade
