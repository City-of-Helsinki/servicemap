define [
    'i18next',
    'cs!app/views/base'
],
(
    {t: t},
    {SMItemView: SMItemView}
) ->
    ServiceMapDisclaimersView: class ServiceMapDisclaimersView extends SMItemView
        template: 'description-of-service'
        className: 'content modal-dialog about'
        events:
            'click .uservoice-link': 'openUserVoice'
            'click .accessibility-stamp': 'onStampClick'
        openUserVoice: (ev) ->
            UserVoice = window.UserVoice || [];
            UserVoice.push ['show', mode: 'contact']
        onStampClick: (ev) ->
            app.commands.execute 'showAccessibilityStampDescription'
            ev.preventDefault()
        serializeData: ->
            lang: p13n.getLanguage()

    ServiceMapAccessibilityDescriptionView: class ServiceMapAccessibilityDescriptionView extends SMItemView
        template: 'description-of-accessibility'
        className: 'content modal-dialog about'
        events:
            'click .uservoice-link': 'openUserVoice'
        serializeData: ->
            lang: p13n.getLanguage()
        onRender: ->
            @$el.scrollTop()

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
            'click #about-accessibility-stamp': 'onStampClick'
            'click .accessibility-stamp': 'onStampClick'
        onAboutClick: (ev) ->
            app.commands.execute 'showServiceMapDescription'
            ev.preventDefault()
        onStampClick: (ev) ->
            app.commands.execute 'showAccessibilityStampDescription'
            ev.preventDefault()
