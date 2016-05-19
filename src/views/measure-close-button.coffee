define [
    'cs!app/views/base'
], (base) ->

    class MeasureCloseButtonView extends base.SMLayout
        template: 'measure-close-button'
        className: 'measure-tool'
        name: i18n.t 'tools.measure_close'
        events:
            'click': 'closeMeasure'
        closeMeasure: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.getRegion('map').currentView.turnOffMeasureTool()
        render: ->
            super()
            @el
