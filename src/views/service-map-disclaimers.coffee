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
        className: 'content modal-dialog about'
        serializeData: ->
            lang: p13n.getLanguage()
    ServiceMapDisclaimersOverlayView: class ServiceMapDisclaimersOverlayView extends SMItemView
        template: 'disclaimers-overlay'
        serializeData: ->
            layer = p13n.get('map_background_layer')
            if layer in ['servicemap', 'accessible_map']
                copyrightLink = "https://www.openstreetmap.org/copyright"
            copyright: t "disclaimer.copyright.#{layer}"
            copyrightLink: copyrightLink
        events:
            'click #about-the-service': 'onAboutClick'
            'click #map-copyright': 'onCopyrightClick'
        onAboutClick: (ev) ->
            app.commands.execute 'showServiceMapDescription'
        onCopyrightClick: (ev) ->
            # TODO: why doesn't link work statically
            href = ev.currentTarget.href
            window.open href, "_blank"
