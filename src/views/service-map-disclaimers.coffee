define (require) ->
    {t}                 = require 'i18next'

    {SMItemView}        = require 'cs!app/views/base'
    tour                = require 'cs!app/tour'
    TourStartButtonView = require 'cs!app/views/feature-tour-start'

    ServiceMapDisclaimersView: class ServiceMapDisclaimersView extends SMItemView
        template: 'description-of-service'
        className: 'content modal-dialog about'
        events:
            'click .feedback-link': 'openFeedback'
            'click .start-tour-button': 'onTourStart'
        openFeedback: (ev) ->
            app.request 'composeFeedback', null, null
        onTourStart: (ev) ->
            $('#feedback-form-container').modal('hide');
            tour.startTour()
            app.getRegion('tourStart').currentView.trigger 'close'
            @remove();
        serializeData: ->
            lang: p13n.getLanguage()

    ServiceMapAccessibilityDescriptionView: class ServiceMapAccessibilityDescriptionView extends SMItemView
        template: 'description-of-accessibility'
        className: 'content modal-dialog about'
        events:
            'click .uservoice-link': 'openUserVoice'
        serializeData: ->
            lang: p13n.getLanguage()
        onDomRefresh: ->
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
        onAboutClick: (ev) ->
            app.request 'showServiceMapDescription'
            ev.preventDefault()
