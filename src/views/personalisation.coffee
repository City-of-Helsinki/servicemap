define (require) ->
    _                                = require 'underscore'
    p13n                             = require 'cs!app/p13n'
    base                             = require 'cs!app/views/base'
    AccessibilityPersonalisationView = require 'cs!app/views/accessibility-personalisation'
    {getLangURL}                     = require 'cs!app/base'
    Analytics                = require 'cs!app/analytics'

    class PersonalisationView extends base.SMLayout
        className: 'personalisation-container'
        template: 'personalisation'
        regions:
            accessibility: '#accessibility-personalisation'
        events: ->
            'click .personalisation-button': 'personalisationButtonClick'
            'keydown .personalisation-button': @keyboardHandler @personalisationButtonClick, ['space', 'enter']
            'click .ok-button': 'toggleMenu'
            'keydown .ok-button': @keyboardHandler @toggleMenu, ['space']
            'click .select-on-map': 'selectOnMap'
            'click .personalisations a': 'switchPersonalisation'
            'keydown .personalisations a': @keyboardHandler @switchPersonalisation, ['space']
            'click .personalisation-message a': 'openMenuFromMessage'
            'click .personalisation-message .close-button': 'closeMessage'

        personalisationIcons:
            'city': [
                'helsinki'
                'espoo'
                'vantaa'
                'kauniainen'
            ]
            'senses': [
                'hearing_aid'
                'visually_impaired'
                'colour_blind'
            ]
            'mobility': [
                'wheelchair'
                'reduced_mobility'
                'rollator'
                'stroller'
            ]

        initialize: ->
            $(window).resize @setMaxHeight
            @listenTo p13n, 'change', ->
                @setActivations()
                @renderIconsForSelectedModes()
            @listenTo p13n, 'user:open', -> @personalisationButtonClick()
            @_triggerProfileAnalytics = _.debounce () =>
                @_sendCurrentProfile()
            , 3000
        serializeData: ->
            lang: p13n.getLanguage()

        personalisationButtonClick: (ev) ->
            ev?.preventDefault()
            unless $('#personalisation').hasClass('open')
                @toggleMenu(ev)

        toggleMenu: (ev) ->
            ev?.preventDefault()
            $('#personalisation').toggleClass('open')

        openMenuFromMessage: (ev) ->
            ev?.preventDefault()
            @toggleMenu()
            @closeMessage()

        closeMessage: (ev) ->
            @$('.personalisation-message').removeClass('open')

        selectOnMap: (ev) ->
            # Add here functionality for seleecting user's location from the map.
            ev.preventDefault()

        renderIconsForSelectedModes: ->
            $container = @$('.selected-personalisations').empty()
            for group, types of @personalisationIcons
                for type in types
                    if @modeIsActivated(type, group)
                        if group == 'city'
                            iconClass = 'icon-icon-coat-of-arms-' + type.split('_').join('-')
                        else
                            iconClass = 'icon-icon-' + type.split('_').join('-')
                        $icon = $("<span class='#{iconClass}'></span>")
                        $container.append($icon)

        modeIsActivated: (type, group) ->
            activated = false
            # FIXME
            if group == 'city'
                activated = p13n.get('city')[type]
            else if group == 'mobility'
                activated = p13n.getAccessibilityMode('mobility') == type
            else if group == 'language'
                activated = p13n.getLanguage() == type
            else
                activated = p13n.getAccessibilityMode type
            return activated

        setActivations: ->
            $list = @$el.find '.personalisations'
            $list.find('li').each (idx, li) =>
                $li = $(li)
                type = $li.data 'type'
                group = $li.data 'group'
                $button = $li.find('a[role="button"]')
                activated = @modeIsActivated(type, group)
                if activated
                    $li.addClass 'selected'
                else
                    $li.removeClass 'selected'
                $button.attr 'aria-pressed', activated

        _sendCurrentProfile: ->
            _.each p13n.getCities(), (city) ->
                Analytics.trackCommand 'setProfileCity', [city, 1]

            accessibility = p13n.getAccessibilityModes()
            _.each _.keys(accessibility), (key) ->
                if key == 'mobility'
                    Analytics.trackCommand 'setProfileMobility', [accessibility[key], 1]
                else
                    if !!accessibility[key]
                        Analytics.trackCommand 'setProfileSenses', [key, 1]

        switchPersonalisation: (ev) =>
            ev.preventDefault()
            parentLi = $(ev.target).closest 'li'
            group = parentLi.data 'group'
            type = parentLi.data 'type'

            if group == 'mobility'
                p13n.toggleMobility type
            else if group == 'senses'
                modeIsSet = p13n.toggleAccessibilityMode type
                currentBackground = p13n.get 'map_background_layer'
                if type in ['visually_impaired', 'colour_blind']
                    newBackground = null
                    if modeIsSet
                        newBackground = 'accessible_map'
                    else if currentBackground == 'accessible_map'
                        if p13n.getAccessibilityMode('visually_impaired') || p13n.getAccessibilityMode('colour_blind')
                            newBackground = 'accessible_map'
                        else
                            newBackground = 'servicemap'
                    if newBackground
                        p13n.setMapBackgroundLayer newBackground
            else if group == 'city'
                p13n.toggleCity type
            else if group == 'language'
                window.location.href = getLangURL type
            @_triggerProfileAnalytics()

        onDomRefresh: ->
            @renderIconsForSelectedModes()
            @setActivations()
            @setMaxHeight()

        onShow: ->
            viewPoints = []
            @accessibility.show new AccessibilityPersonalisationView({activeModes: viewPoints})

        setMaxHeight: =>
            # TODO: Refactor this when we get some onDomAppend event.
            # The onRender function that calls setMaxHeight runs before @el
            # is inserted into DOM. Hence calculating heights and positions of
            # the template elements is currently impossible.
            personalisationHeaderHeight = 56
            windowWidth = $(window).width()
            offset = 0
            if windowWidth >= appSettings.mobile_ui_breakpoint
                offset = $('#personalisation').offset().top
            maxHeight = $(window).innerHeight() - personalisationHeaderHeight - offset
            @$el.find('.personalisation-content').css 'max-height': maxHeight
