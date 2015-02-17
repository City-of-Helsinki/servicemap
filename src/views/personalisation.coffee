define [
    'app/p13n',
    'app/views/base',
], (
    p13n,
    base
)  ->

    class PersonalisationView extends base.SMItemView
        className: 'personalisation-container'
        template: 'personalisation'
        events:
            'click .personalisation-button': 'personalisationButtonClick'
            'click .ok-button': 'toggleMenu'
            'click .select-on-map': 'selectOnMap'
            'click .personalisations a': 'switchPersonalisation'
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
                activated = p13n.get('city') == type
            else if group == 'mobility'
                activated = p13n.getAccessibilityMode('mobility') == type
            else
                activated = p13n.getAccessibilityMode type
            return activated

        setActivations: ->
            $list = @$el.find '.personalisations'
            $list.find('li').each (idx, li) =>
                $li = $(li)
                type = $li.data 'type'
                group = $li.data 'group'
                if @modeIsActivated(type, group)
                    $li.addClass 'selected'
                else
                    $li.removeClass 'selected'

        switchPersonalisation: (ev) ->
            ev.preventDefault()
            parentLi = $(ev.target).closest 'li'
            group = parentLi.data 'group'
            type = parentLi.data 'type'

            if group == 'mobility'
                p13n.toggleMobility type
            else if group == 'senses'
                val = p13n.toggleAccessibilityMode type
                currentBackground = p13n.get 'map_background_layer'
                newBackground = if val
                    'accessible_map'
                else if currentBackground == 'accessible_map'
                    'servicemap'
                p13n.setMapBackgroundLayer newBackground
            else if group == 'city'
                p13n.toggleCity type

        render: (opts) ->
            super opts
            @renderIconsForSelectedModes()
            @setActivations()

        onRender: ->
            @setMaxHeight()

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
