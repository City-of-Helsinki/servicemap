define [
    'cs!app/views/base'
], (base) ->

    class MeasureCloseButtonView extends base.SMLayout
        template: 'location-refresh-button'
        className: 'asdf'
        events:
            'click': 'closeMeasure'
        closeMeasure: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.getRegion('map').currentView.turnOffMeasureTool()
        render: ->
            super()
            @el
