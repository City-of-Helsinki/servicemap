define (require) ->
    models = require 'cs!app/models'
    sm     = require 'cs!app/base'
    $      = require 'jquery'
    URI    = require 'URI'

    BACKEND_BASE = appSettings.service_map_backend

    class RedirectUnit extends models.Unit
        resourceName: 'redirect/unit'

    class RedirectUnitList extends models.UnitList
        model: RedirectUnit

    renderUnitsByOldServiceId = (queryParameters, cancelToken, appModelUnits, appModelRedirectFilter, control) ->
        uri = URI BACKEND_BASE
        uri.segment '/redirect/unit/'
        uri.setSearch queryParameters
        sm.withDeferred (deferred) =>
            $.ajax
                url: uri.toString()
                success: (result) =>
                    control.renderUnit('', {query: result}, cancelToken).then => deferred.resolve()

    return renderUnitsByOldServiceId
