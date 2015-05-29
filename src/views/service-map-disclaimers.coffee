define [
    'i18next',
    'app/views/base'
],
(
    {t: t},
    {SMItemView: SMItemView}
) ->
    ServiceMapDisclaimersView: class ServiceMapDisclaimersView extends SMItemView
        template: 'description-of-service'
        serializeData:
            lang: p13n.getLanguage()
    ServiceMapDisclaimersOverlayView: class ServiceMapDisclaimersOverlayView extends SMItemView
        template: 'disclaimers-overlay'
        serializeData: ->
            layer = p13n.get('map_background_layer')
            copyright: t "disclaimer.copyright.#{layer}"
