define [
    'cs!app/views/base',
    'cs!app/util/export',
], (
    sm,
    ExportUtils,
) ->

    FORMATS = [
        {id: 'kml', text: 'KML', description: 'Google Maps, Google Earth, GIS'},
        {id: 'json', text: 'JSON', description: 'Developers'}
    ]

    class ExportingView extends sm.SMItemView
        template: 'export'
        className: 'content modal-dialog export'
        events:
            "change input[name='options']": "inputChange"
        initialize: (@models) ->
            @activeFormat = 'kml'
        serializeData: ->
            activeFormat = _(FORMATS).filter((f) => f.id == @activeFormat)[0]

            formats: FORMATS
            exportUrl: ExportUtils.exportLink activeFormat.id, @models
            activeFormat: activeFormat

        inputChange: (ev) ->
            @activeFormat = $(ev.currentTarget).data 'format'
            @render()
