define ->

    class ServiceTreeView extends base.SMLayout
        id: 'service-tree-container'
        className: 'navigation-element'
        template: 'service-tree'
        events:
            'click .service.has-children': 'open_service'
            'click .service.parent': 'open_service'
            'click .crumb': 'handle_breadcrumb_click'
            'click .service.leaf': 'toggle_leaf'
            'click .service .show-icon': 'toggle_button'
            'mouseenter .service .show-icon': 'show_tooltip'
            'mouseleave .service .show-icon': 'remove_tooltip'
        type: 'service-tree'

        initialize: (options) ->
            @selected_services = options.selected_services
            @breadcrumbs = options.breadcrumbs
            @animation_type = 'left'
            @scrollPosition = 0
            @listenTo @selected_services, 'remove', @render
            @listenTo @selected_services, 'add', @render
            @listenTo @selected_services, 'reset', @render

        toggle_leaf: (event) ->
            @toggle_element($(event.currentTarget).find('.show-icon'))

        toggle_button: (event) ->
            @remove_tooltip()
            event.preventDefault()
            event.stopPropagation()
            @toggle_element($(event.target))

        show_tooltip: (event) ->
            @remove_tooltip()
            @$tooltip_element = $("<div id=\"tooltip\">#{i18n.t('sidebar.show_tooltip')}</div>")
            $target_el = $(event.currentTarget)
            $('body').append @$tooltip_element
            button_offset = $target_el.offset()
            original_offset = @$tooltip_element.offset()
            @$tooltip_element.css 'top', "#{button_offset.top + original_offset.top}px"
            @$tooltip_element.css 'left', "#{button_offset.left + original_offset.left}px"
        remove_tooltip: (event) ->
            @$tooltip_element?.remove()

        get_show_icon_classes: (showing, root_id) ->
            if showing
                return "show-icon selected service-color-#{root_id}"
            else
                return "show-icon service-hover-color-#{root_id}"

        toggle_element: ($target_element) ->
            service_id = $target_element.closest('li').data('service-id')
            unless @selected(service_id) is true
                app.commands.execute 'clearSearchResults'
                service = new models.Service id: service_id
                service.fetch
                    success: =>
                        app.commands.execute 'addService', service
            else
                app.commands.execute 'removeService', service_id

        handle_breadcrumb_click: (event) ->
            event.preventDefault()
            # We need to stop the event from bubling to the containing element.
            # That would make the service tree go back only one step even if
            # user is clicking an earlier point in breadcrumbs.
            event.stopPropagation()
            @open_service(event)

        open_service: (event) ->
            $target = $(event.currentTarget)
            service_id = $target.data('service-id')
            service_name = $target.data('service-name')
            @animation_type = $target.data('slide-direction')

            if not service_id
                return null

            if service_id == 'root'
                service_id = null
                # Use splice to affect the original breadcrumbs array.
                @breadcrumbs.splice 0, @breadcrumbs.length
            else
                # See if the service is already in the breadcrumbs.
                index = _.indexOf(_.pluck(@breadcrumbs, 'service_id'), service_id)
                if index != -1
                    # Use splice to affect the original breadcrumbs array.
                    @breadcrumbs.splice index, @breadcrumbs.length - index
                @breadcrumbs.push(service_id: service_id, service_name: service_name)

            spinner_options =
                container: $target.get(0)
                hide_container_content: true
            @collection.expand service_id, spinner_options

        onRender: ->
            if @service_to_display
                $target_element = @$el.find("[data-service-id=#{@service_to_display.id}]").find('.show-icon')
                @service_to_display = false
                @toggle_element($target_element)

            $ul = @$el.find('ul')
            $ul.on('scroll', (ev) =>
                @scrollPosition = ev.currentTarget.scrollTop)
            $ul.scrollTop(@scrollPosition)
            @scrollPosition = 0
            @set_breadcrumb_widths()

        set_breadcrumb_widths: ->
            CRUMB_MIN_WIDTH = 40
            # We need to use the last() jQuery method here, because at this
            # point the animations are still running and the DOM contains,
            # both the old and the new content. We only want to get the new
            # content and its breadcrumbs as a basis for our calculations.
            $container = @$el.find('.header-item').last()
            $crumbs = $container.find('.crumb')
            return unless $crumbs.length > 1

            # The last breadcrumb is given preference, so separate that from the
            # rest of the breadcrumbs.
            $last_crumb = $crumbs.last()
            $crumbs = $crumbs.not(':last')

            $chevrons = $container.find('.icon-icon-forward')
            space_available = $container.width() - ($chevrons.length * $chevrons.first().outerWidth())
            last_width = $last_crumb.width()
            space_needed = last_width + $crumbs.length * CRUMB_MIN_WIDTH

            if space_needed > space_available
                # Not enough space -> make the last breadcrumb narrower.
                last_width = space_available - $crumbs.length * CRUMB_MIN_WIDTH
                $last_crumb.css('max-width': last_width)
                $crumbs.css('max-width': CRUMB_MIN_WIDTH)
            else
                # More space -> Make the other breadcrumbs wider.
                crumb_width = (space_available - last_width) / $crumbs.length
                $crumbs.css('max-width': crumb_width)

        selected: (service_id) ->
            @selected_services.get(service_id)?
        close: ->
            @remove_tooltip()
            @remove()
            @stopListening()

        serializeData: ->
            classes = (category) ->
                if category.get('children').length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                selected = @selected(category.id)

                root_id = category.get 'root'

                id: category.get 'id'
                name: category.get_text 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: selected
                root_id: root_id
                show_icon_classes: @get_show_icon_classes selected, root_id

            parent_item = {}
            back = null

            if @collection.chosen_service
                back = @collection.chosen_service.get('parent') or 'root'
                parent_item.name = @collection.chosen_service.get_text 'name'
                parent_item.root_id = @collection.chosen_service.get 'root'

            data =
                back: back
                parent_item: parent_item
                list_items: list_items
                breadcrumbs: _.initial @breadcrumbs # everything but the last crumb

