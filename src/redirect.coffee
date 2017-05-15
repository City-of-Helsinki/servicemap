define (require) ->
    sm     = require 'cs!app/base'
    $      = require 'jquery'
    URI    = require 'URI'
    Raven  = require 'raven'

    BACKEND_BASE = appSettings.service_map_backend

    renderUnitsByOldServiceId = (queryParameters, control, cancelToken) ->
        uri = URI BACKEND_BASE
        uri.segment '/redirect/unit/'
        uri.setSearch queryParameters
        sm.withDeferred (deferred) =>
            $.ajax
                url: uri.toString()
                success: (result) =>
                    control.renderUnit('', {query: result}, cancelToken).then => deferred.resolve()
                error: (result) =>
                    Raven.captureMessage(
                        'No redirect found for old service',
                        tags:
                            type: 'helfi_rest_api_v4_redirect'
                            service_id: queryParameters.service)
                    deferred.resolve()

    return renderUnitsByOldServiceId
