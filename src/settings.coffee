define 'app/settings', () ->

    applyAjaxDefaults = (settings) ->
        settings.dataType = sm_settings.ajax_format
        settings.cache = sm_settings.ajax_cache
        settings.jsonpCallback = sm_settings.ajax_jsonpCallback
        settings.data = settings.data || {}
        settings.data.format = sm_settings.ajax_format
        return settings

    return {
        applyAjaxDefaults: applyAjaxDefaults
    }
