define ->

    ieVersion = getIeVersion()

    applyAjaxDefaults = (settings) ->
        settings.cache = true
        if not ieVersion
            return settings
        if ieVersion >= 10
            return settings

        # JSONP for older IEs
        settings.dataType = 'jsonp'
        settings.data = settings.data || {}
        settings.data.format = 'jsonp'
        return settings

    return {
        applyAjaxDefaults: applyAjaxDefaults
    }
