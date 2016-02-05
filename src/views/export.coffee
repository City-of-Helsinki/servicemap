define [
    'bootstrap',
    'cs!app/views/base',
    'cs!app/util/export',
], (
    bs,
    sm,
    ExportUtils,
) ->

    FORMATS = [
        {id: 'kml', text: 'KML', description: 'Google Maps, Google Earth, GIS'},
        {id: 'json', text: 'JSON', description: 'Developers'}
    ]

    class ExportingView extends sm.SMItemView
        template: 'export'
        id: 'exporting-modal'
        className: 'modal-dialog content export'
        events:
            "change input[name='options']": "inputChange"
            'click #exporting-submit': 'close'
        initialize: (@models) ->
            @activeFormat = 'kml'
        serializeData: ->
            activeFormat = _(FORMATS).filter((f) => f.id == @activeFormat)[0]
            formats: FORMATS
            specs: ExportUtils.exportSpecification activeFormat.id, @models
            activeFormat: activeFormat

        inputChange: (ev) ->
            @activeFormat = $(ev.currentTarget).data 'format'
            @render()
        close: (ev) ->
            @$el.closest('.modal').modal 'hide'
            return true
