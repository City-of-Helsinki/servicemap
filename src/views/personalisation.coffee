define ->

    class PersonalisationView extends base.SMItemView
        className: 'personalisation-container'
        template: 'personalisation'
        events:
            'click .personalisation-button': 'personalisation_button_click'
            'click .ok-button': 'toggle_menu'
            'click .select-on-map': 'select_on_map'
            'click .personalisations a': 'switch_personalisation'
            'click .personalisation-message a': 'open_menu_from_message'
            'click .personalisation-message .close-button': 'close_message'

        personalisation_icons:
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
            $(window).resize @set_max_height
            @listenTo p13n, 'change', ->
                @set_activations()
                @render_icons_for_selected_modes()
            @listenTo p13n, 'user:open', -> @personalisation_button_click()

        personalisation_button_click: (ev) ->
            ev?.preventDefault()
            unless $('#personalisation').hasClass('open')
                @toggle_menu(ev)

        toggle_menu: (ev) ->
            ev?.preventDefault()
            $('#personalisation').toggleClass('open')

        open_menu_from_message: (ev) ->
            ev?.preventDefault()
            @toggle_menu()
            @close_message()

        close_message: (ev) ->
            @$('.personalisation-message').removeClass('open')

        select_on_map: (ev) ->
            # Add here functionality for seleecting user's location from the map.
            ev.preventDefault()

        render_icons_for_selected_modes: ->
            $container = @$('.selected-personalisations').empty()
            for group, types of @personalisation_icons
                for type in types
                    if @mode_is_activated(type, group)
                        if group == 'city'
                            icon_class = 'icon-icon-coat-of-arms-' + type.split('_').join('-')
                        else
                            icon_class = 'icon-icon-' + type.split('_').join('-')
                        $icon = $("<span class='#{icon_class}'></span>")
                        $container.append($icon)

        mode_is_activated: (type, group) ->
            activated = false
            # FIXME
            if group == 'city'
                activated = p13n.get('city') == type
            else if group == 'mobility'
                activated = p13n.get_accessibility_mode('mobility') == type
            else
                activated = p13n.get_accessibility_mode type
            return activated

        set_activations: ->
            $list = @$el.find '.personalisations'
            $list.find('li').each (idx, li) =>
                $li = $(li)
                type = $li.data 'type'
                group = $li.data 'group'
                if @mode_is_activated(type, group)
                    $li.addClass 'selected'
                else
                    $li.removeClass 'selected'

        switch_personalisation: (ev) ->
            ev.preventDefault()
            parent_li = $(ev.target).closest 'li'
            group = parent_li.data 'group'
            type = parent_li.data 'type'

            if group == 'mobility'
                p13n.toggle_mobility type
            else if group == 'senses'
                p13n.toggle_accessibility_mode type
            else if group == 'city'
                p13n.toggle_city type

        render: (opts) ->
            super opts
            @render_icons_for_selected_modes()
            @set_activations()

        onRender: ->
            @set_max_height()

        set_max_height: =>
            # TODO: Refactor this when we get some onDomAppend event.
            # The onRender function that calls set_max_height runs before @el
            # is inserted into DOM. Hence calculating heights and positions of
            # the template elements is currently impossible.
            personalisation_header_height = 56
            window_width = $(window).width()
            offset = 0
            if window_width >= MOBILE_UI_BREAKPOINT
                offset = $('#personalisation').offset().top
            max_height = $(window).innerHeight() - personalisation_header_height - offset
            @$el.find('.personalisation-content').css 'max-height': max_height
