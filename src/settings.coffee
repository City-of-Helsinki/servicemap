define ->

    ie_version = get_ie_version()

    applyAjaxDefaults = (settings) ->
        settings.cache = true
        if not ie_version
            return settings
        if ie_version >= 10
            return settings

        # JSONP for older IEs
        settings.dataType = 'jsonp'
        settings.data = settings.data || {}
        settings.data.format = 'jsonp'
        return settings

    return {
        applyAjaxDefaults: applyAjaxDefaults
    }
