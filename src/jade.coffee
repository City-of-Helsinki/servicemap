define 'app/jade', ['underscore', 'jquery', 'i18next', 'app/p13n', 'app/dateformat'], (_, $, i18n, p13n, dateformat) ->
    # Make sure jade runtime is loaded
    if typeof jade != 'object'
        throw new Error "Jade not loaded before app"

    set_helper = (data, name, helper) ->
        if name of data
            return
        data[name] = helper

    class Jade
        get_template: (name) ->
            key = "views/templates/#{name}"
            if key not of JST
                throw new Error "template '#{name}' not loaded"
            template_func = JST[key]
            return template_func

        t_attr: (attr) ->
            return p13n.get_translated_attr attr
        t_attr_has_lang: (attr) ->
            if not attr
                return false
            return p13n.get_language() of attr
        phone_i18n: (num) ->
            if num.indexOf '0' == 0
                # FIXME: make configurable
                num = '+358' + num.substring 1
            num = num.replace /\s/g, ''
            num = num.replace /-/g, ''
            return num
        static_path: (path) ->
            # Strip leading slash
            if path.indexOf('/') == 0
                path = path.substring 1
            return app_settings.static_path + path
        human_date: (start_time, end_time) ->
            formatted = dateformat.humanize_event_datetime(
                start_time, end_time, 'small', has_end_time=false
            )
            return formatted.date
        uppercase_first: (val) ->
            val.charAt(0).toUpperCase() + val.slice 1

        mixin_helpers: (data) ->
            set_helper data, 't', i18n.t
            set_helper data, 't_attr', @t_attr
            set_helper data, 't_attr_has_lang', @t_attr_has_lang
            set_helper data, 'phone_i18n', @phone_i18n
            set_helper data, 'static_path', @static_path
            set_helper data, 'human_date', @human_date
            set_helper data, 'uppercase_first', @uppercase_first
            data

        template: (name, locals) ->
            if locals?
                if typeof locals != 'object'
                    throw new Error "template must get an object argument"
            else
                locals = {}
            func = @get_template name
            data = _.clone locals
            @mixin_helpers data
            template_str = func data
            return $.trim template_str

    return new Jade
