define [
    'cs!app/views/base'
], (
    sm
) ->

    class ExportingView extends sm.SMItemView
        template: 'export'
        className: 'content modal-dialog about'
        serializeData: ->
            formats: [
                {text: 'KML', active: true, description: '(Google Maps, Google Earth, GIS)'},
                {text: 'JSON', active: false, description: null}]
