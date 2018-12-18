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
            'city': [
                'helsinki'
                'espoo'
                'vantaa'
                'kauniainen'
            ]

        initialize: ->
            $(window).resize @setMaxHeight
            @listenTo p13n, 'change', ->
                @setActivations()
                @renderIconsForSelectedModes()
            @listenTo p13n, 'user:open', -> @personalisationButtonClick()
            # These selectors are used when closing the personalisation menu to regain focus in relevant page section
            @focusAfterCloseMenu = null
            @focusAfterCloseMenuBackup = null

        serializeData: ->
            lang: p13n.getLanguage()

        _getSelector: ($element) ->
          selector = ""
          id = $element.attr("id")
          if id
            selector += "#"+ id

          classNames = $element.attr("class")
          if classNames
            selector += "." + $.trim(classNames).replace(/\s/gi, ".")
          selector

        _findBackupParentLink: ($element) ->
            # We assume that user has opened personalisation menu from one of the
            # collapsed sections so as a backup focus element we pick first link inside section.
            $element.parents('.section').find('a').first()

        personalisationButtonClick: (ev) ->
            ev?.preventDefault()
            @focusAfterCloseMenu = @_getSelector $(document.activeElement)
            @focusAfterCloseMenuBackup = @_getSelector @_findBackupParentLink($(document.activeElement))
            unless $('#personalisation').hasClass('open')
                @toggleMenu(ev)
                # When opening the menu, focus on the first of the menu
                $('.personalisation-content a').first().focus()

        toggleMenu: (ev) ->
            ev?.preventDefault()
            $('#personalisation').toggleClass('open')
            unless $('#personalisation').hasClass('open')
                elementToFocusAfterClose = if $(@focusAfterCloseMenu).length > 0 then $(@focusAfterCloseMenu) else $(@focusAfterCloseMenuBackup)
                elementToFocusAfterClose.focus()
                @focusAfterCloseMenu = null
                @focusAfterCloseMenuBackup = null

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

        _sendProfileClickToAnalytics:(group, type) ->
            category = null
            name = type
            value = 0
            if group == 'city'
                category = "setProfileCity"
                value += type in p13n.getCities()
            else if group == 'senses'
                category = "setProfileSenses"
                value += p13n.getAccessibilityMode(type)
            else if group == 'mobility'
                category = "setProfileMobility"
                value += type == p13n.getAccessibilityMode(group)

            if value == 0
                value = -1
            Analytics.trackCommand category, [name, value]

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
            @_sendProfileClickToAnalytics(group, type)

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
