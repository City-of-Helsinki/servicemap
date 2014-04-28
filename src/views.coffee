define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'TweenLite', 'app/p13n', 'app/widgets', 'app/jade', 'app/models', 'app/search', 'app/color'], (_, Backbone, Marionette, Leaflet, i18n, TweenLite, p13n, widgets, jade, models, search, colors) ->

    class SMItemView extends Marionette.ItemView
        templateHelpers:
            t: i18n.t
        getTemplate: ->
            return jade.get_template @template

    class AppView extends Backbone.View
        initialize: (options)->
            @service_sidebar = new ServiceSidebarView
                parent: this
                service_tree_collection: options.service_list
            options.map_view.addControl 'sidebar', @service_sidebar.map_control()
            @map = options.map_view.map
            @current_markers = {}
            @details_marker = null # The marker currently visible on details view.
            @all_markers = L.layerGroup()
            @listenTo app.vent, 'unit:render-one', @render_unit

        render: ->
            return this

        render_unit: (id)->
            unit = new models.Unit id: id
            unit.fetch
                success: =>
                    unit_list = new models.UnitList [unit]
                    @clear_all_markers()
                    @draw_units unit_list, zoom: true, drawMarker: true
                error: ->
                    # TODO: decide where to route if route has invalid unit id.


        clear_all_markers: ->
            @all_markers.clearLayers()

        remember_markers: (service_id, markers) ->
            @current_markers[service_id] = markers
        remove_service_points: (service_id) ->
            _.each @current_markers[service_id], (marker) =>
                @map.removeLayer marker
            delete @current_markers[service_id]

        add_service_points: (service, on_success, spinner_target = null) ->
            unit_list = new models.UnitList()
            unit_list.fetch
                data:
                    service: service.id
                    page_size: 1000
                    only: 'name,location'
                spinner_target: spinner_target
                success: =>
                    markers = @draw_units unit_list,
                        service: service
                    @remember_markers service.id, markers
                    on_success?()

        draw_units: (unit_list, opts) ->
            markers = []
            if opts.service?
                color = colors.service_color(opts.service)
            else
                color = null

            unit_list.each (unit) =>
                if !color?
                    color = colors.unit_color(unit)
                icon = new widgets.CanvasIcon 50, color
                location = unit.get('location')
                if location?
                    coords = location.coordinates
                    popup = L.popup(closeButton: false).setContent "<div class='unit-name'>#{unit.get_text 'name'}</div>"
                    marker = L.marker([coords[1], coords[0]], icon: icon)
                        .bindPopup(popup)

                    @all_markers.addLayer marker

                    marker.unit = unit
                    unit.marker = marker
                    markers.push marker
                    marker.on 'click', (event) =>
                        marker = event.target
                        @service_sidebar.show_details marker.unit
                        @details_marker?.closePopup()
                        popup.addTo(@map)
                        @details_marker = marker
                    marker.on 'mouseover', (event) ->
                        event.target.openPopup()

            @all_markers.addTo @map
            bounds = L.latLngBounds (m.getLatLng() for m in markers)
            bounds = bounds.pad 0.05
            # FIXME: map.fitBounds() maybe?
            if opts? and opts.zoom and unit_list.length == 1
                coords = unit_list.first().get('location').coordinates
                @map.setView [coords[1], coords[0]], 12

            return markers

        # The transitions triggered by removing the class landing from body are defined
        # in the file landing-page.less.
        # When key animations have ended a 'landing-page-cleared' event is triggered.
        clear_landing_page: () ->
            if $('body').hasClass('landing')
                $('body').removeClass('landing')
                $('.service-sidebar').on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', (event) ->
                    if event.originalEvent.propertyName is 'top'
                        app.vent.trigger('landing-page-cleared')
                        $(@).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd')
                )


    class ServiceSidebarView extends Backbone.View
        tagName: 'div'
        className: 'service-sidebar'
        events:
            'typeahead:selected': 'autosuggest_show_details'
            'click .header': 'open'
            'click .close-button': 'close'

        initialize: (options) ->
            @parent = options.parent
            @service_tree_collection = options.service_tree_collection
            @render()

        map_control: ->
            return new widgets.ServiceSidebarControl @el

        open: (event) ->
            event.preventDefault()
            if @prevent_switch
                @prevent_switch = false
                return
            @parent.clear_landing_page()

            header_type = $(event.currentTarget).data('type')
            if header_type is 'search'
                @open_search()
            if header_type is 'browse'
                @open_service_tree()

        open_search: ->
            @$el.find('input').select()
            unless @$el.find('.container').hasClass('search-open')
                @update_classess('search')

        open_service_tree: ->
            unless @$el.find('.container').hasClass('browse-open')
                @update_classess('browse')

        close: (event) ->
            event.preventDefault()
            event.stopPropagation()

            header_type = $(event.target).closest('.header').data('type')
            @$el.find('.container').removeClass().addClass('container')
            @update_classess()

            # Clear search query if search is closed.
            if header_type is 'search'
                @$el.find('input').val('')

        update_classess: (opening) ->
            $container = @$el.find('.container')
            $container.removeClass().addClass('container')

            if opening is 'search'
                $container.addClass('search-open')
                @$el.find('.service-tree').css('max-height': 0)
            else if opening is 'browse'
                $container.addClass('browse-open')
                @service_tree.set_max_height()
            else
                @$el.find('.service-tree').css('max-height': 0)

        autosuggest_show_details: (ev, data, _) ->
            @prevent_switch = true
            if data.object_type == 'unit'
                @show_details new models.Unit(data),
                    zoom: true
                    draw_marker: true
            else if data.object_type == 'service'
                @open_service_tree()
                @service_tree.show_service(new models.Service(data))

        show_details: (unit, opts) ->
            if not opts
                opts = {}

            @$el.find('.container').addClass('details-open')
            @details_view.model = unit
            unit.fetch(success: =>
                @details_view.render()
            )
            @details_view.render()
            if opts.draw_marker
                unit_list = new models.UnitList [unit]
                @parent.draw_units unit_list, opts

            # Set for console access
            window.debug_unit = unit

        hide_details: ->
            @$el.find('.container').removeClass('details-open')

        enable_typeahead: (selector) ->
            @$el.find(selector).typeahead null,
                source: search.engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx

        render: ->
            s1 = i18n.t 'sidebar.search'
            if not s1
                console.log i18n
                throw 'i18n not initialized'
            template_string = jade.template 'service-sidebar'
            @el.innerHTML = template_string
            @enable_typeahead('input.form-control[type=search]')

            @service_tree = new ServiceTreeView
                collection: @service_tree_collection
                app_view: @parent
                el: @$el.find('#service-tree-container')

            @details_view = new DetailsView
                el: @$el.find('#details-view-container')
                parent: @
                model: new models.Unit()

            return @el


    class DetailsView extends Backbone.View
        events:
            'click .back-button': 'close'

        initialize: (options) ->
            @parent = options.parent

        close: (event) ->
            event.preventDefault()
            @parent.hide_details()

        set_max_height: () ->
            # Set the details view content max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.find('.content').offset().top
            @$el.find('.content').css 'max-height': max_height

        render: ->
            data = @model.toJSON()
            template_string = jade.template 'details', data
            @el.innerHTML = template_string
            @set_max_height()

            return @el


    class ServiceTreeView extends Backbone.View
        events:
            'click .service.has-children': 'open'
            'click .service.parent': 'open'
            'click .service.leaf': 'toggle_leaf'
            'click .service .show-button': 'toggle_button'

        initialize: (options) ->
            @app_view = options.app_view
            @showing = {}
            @slide_direction = 'left'
            @listenTo @collection, 'sync', @render
            @collection.fetch
                data:
                    level: 0
            app.vent.on('landing-page-cleared', @set_max_height)

        category_url: (id) ->
            '/#/service/' + id

        toggle_leaf: (event) ->
            @toggle_element($(event.currentTarget).find('.show-button'))

        toggle_button: (event) ->
            event.preventDefault()
            event.stopPropagation()
            @toggle_element($(event.target))

        show_service: (service) =>
            @collection.expand service.attributes.parent
            @service_to_display = service

        get_show_button_classes: (showing, root_id) ->
            if showing
                return "show-button selected service-background-color-#{root_id}"
            else
                return "show-button service-hover-background-color-light-#{root_id}"

        toggle_element: ($target_element) ->
            service_id = $target_element.parent().data('service-id')
            root_id = $target_element.parent().data('root-id')
            unless @showing[service_id] is true
                # Button styles should be changed only after all the markers have been drawn.
                on_success = =>
                    $target_element.removeClass().addClass @get_show_button_classes(true, root_id)
                    $target_element.text i18n.t 'sidebar.hide'
                    @showing[service_id] = true
                service = new models.Service id: service_id
                service.fetch
                    success: =>
                        @app_view.add_service_points(service, on_success, $target_element.get(0))
            else
                delete @showing[service_id]
                $target_element.removeClass().addClass @get_show_button_classes(false, root_id)
                $target_element.text i18n.t 'sidebar.show'
                @app_view.remove_service_points(service_id)

        open: (event) ->
            $target = $(event.currentTarget)
            service_id = $target.data('service-id')
            @slide_direction = $target.data('slide-direction')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id, $target.get(0)

        set_max_height: () =>
            # Set the service tree max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.offset().top
            @$el.find('.service-tree').css 'max-height': max_height

        render: ->
            classes = (category) ->
                if category.attributes.children.length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                selected = @showing[category.attributes.id]
                root_id = category.get 'root'
                show_button_classes = @get_show_button_classes selected, root_id

                id: category.get 'id'
                name: category.get_text 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: selected
                root_id: root_id
                show_button_classes: show_button_classes

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
            template_string = jade.template 'service-tree', data

            $old_content = @$el.find('ul')
            if $old_content.length
                # Add content with sliding animation
                @$el.append $(template_string)
                $new_content = @$el.find('.new-content')

                # Calculate how much the new content needs to be moved.
                content_width = $new_content.width()
                content_margin = parseInt($new_content.css('margin-left').replace('px', ''))
                move_distance = content_width + content_margin

                if @slide_direction is 'left'
                    move_distance = "-=#{move_distance}px"
                else
                    move_distance = "+=#{move_distance}px"
                    # Move new content to the left side of the old content
                    $new_content.css 'left': -2 * (content_width + content_margin)

                TweenLite.to([$old_content, $new_content], 0.3, {
                    left: move_distance,
                    ease: Power2.easeOut,
                    onComplete: () ->
                        $old_content.remove()
                        $new_content.css 'left': 0
                        $new_content.removeClass('new-content')
                })

            else
                # Don't use animations if there is no old content
                @$el.append $(template_string)

            if @service_to_display
                $target_element = @$el.find("[data-service-id=#{@service_to_display.id}]").find('.show-button')
                @service_to_display = false
                @toggle_element($target_element)

            @set_max_height()

            return @el


    exports =
        AppView: AppView
        ServiceSidebarView: ServiceSidebarView
        ServiceTreeView: ServiceTreeView

    return exports
