define 'app/settings', () ->

    ie_version = get_ie_version()

    applyAjaxDefaults = (settings) ->
        settings.cache = sm_settings.ajax_cache
        if not ie_version
            return settings
        if ie_version >= 10
            return settings

        settings.dataType = sm_settings.ajax_format
        settings.jsonpCallback = sm_settings.ajax_jsonpCallback
        settings.data = settings.data || {}
        settings.data.format = sm_settings.ajax_format
        return settings

    return {
        applyAjaxDefaults: applyAjaxDefaults
    }
