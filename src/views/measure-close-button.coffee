define (require) ->
    base = require 'cs!app/views/base'
    i18n = require 'i18next'

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
            app.commands.execute "deactivateMeasuringTool"
        render: ->
            super()
            @el
