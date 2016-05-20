define [
    'cs!app/views/base',
    'i18next'
], (base, i18n) ->

    class MeasureCloseButtonView extends base.SMLayout
        template: 'measure-close-button'
        className: 'measure-close-button'
        events:
            'click': 'closeMeasure'

        serializeData: () ->
            closeText: i18n.t 'tools.measure_close'
        closeMeasure: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.commands.execute "deactivateMeasuringTool"
        render: ->
            super()
            @el
