define (require) ->
    i18n = require 'i18next'

    base = require 'cs!app/views/base'

    class MeasureCloseButtonView extends base.SMLayout
        template: 'measure-close-button'
        className: 'measure-close-button'
        events:
            'click': 'closeMeasure'

        serializeData: () ->
            closeText: i18n.t 'measuring_tool.close'
        closeMeasure: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.request "deactivateMeasuringTool"
        render: ->
            super()
            @el
