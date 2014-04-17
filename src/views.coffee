SMBACKEND_BASE_URL = sm_settings.backend_url + '/'

define 'app/views', ['underscore', 'backbone', 'leaflet', 'app/widgets', 'app/map', 'app/models'], (_, Backbone, Leaflet, widgets, map_conf, Models) ->

    class AppView extends Backbone.View
        tagName: 'div'
        initialize: (service_list, options)->
            @service_sidebar = new ServiceSidebarView
                parent: this
                service_tree_collection: service_list

            @map_controls =
                title: new widgets.TitleControl()
#                search: new widgets.SearchControl()
                zoom: L.control.zoom position: 'bottomright'
                scale: L.control.scale imperial: false, maxWidth: 200
                sidebar: L.control.sidebar 'sidebar', position: 'left'
                service_sidebar: @service_sidebar.map_control()
            @current_markers = {}

        service_sidebar_view: () ->
            return @service_sidebar

        render: ->
            @map = map_conf.create_map @$el.find('#map').get(0)

            sidebar = @map_controls.sidebar
            @map_controls.sidebar.on 'hide', ->
                sidebar._active_marker.closePopup()
            @map.on 'click', (ev) ->
                sidebar.hide()

            map = @map
            _.each @map_controls,
                (control, key) -> control.addTo map

            # Disable wheel events to map controls so that the map won't zoom
            # if we try to scroll in a control.
            $('.leaflet-control-container').on 'mousewheel', (ev) ->
                ev.stopPropagation()
                window.target = ev.target
                return

            return this
        remember_markers: (service_id, markers) ->
            @current_markers[service_id] = markers
        remove_service_points: (service_id) ->
            _.each @current_markers[service_id], (marker) =>
                @map.removeLayer marker
            delete @current_markers[service_id]

        add_service_points: (service_id) ->
            # todo: refactor into a model/collection
            params =
                service: service_id
                page_size: 1000
            $.getJSON SMBACKEND_BASE_URL + "unit/", params, (data) =>
                # clear_markers()
                # if division_layer
                #     map.removeLayer division_layer
                markers = @draw_units data.results
                @remember_markers service_id, markers
        draw_units: (unit_list) ->
            # todo: refactor into a model/collection
            # 100 = ei tiedossa, 101 = kunnallinen, 102 = kunnan tukema, 103 = kuntayhtymä,
            # 104 = valtio, 105 = yksityinen
            ptype_to_color =
                100: 'lightgray'
                101: 'blue'
                102: 'lightblue'
                103: 'lightblue'
                104: 'green'
                105: 'orange'
            srv_id_to_icon =
                25344: family: 'fa', name: 'refresh'     # waste management and recycling
                27718: family: 'maki', name: 'school'
                26016: family: 'maki', name: 'restaurant'
                25658: family: 'maki', name: 'monument'
                26018: family: 'maki', name: 'theatre'
                25646: family: 'maki', name: 'theatre'
                25480: family: 'maki', name: 'library'
                25402: family: 'maki', name: 'toilet'
                25676: family: 'maki', name: 'garden'
                26002: family: 'maki', name: 'lodging'
                25536: family: 'fa', name: 'signal'

            markers = []
            for unit in unit_list
                color = ptype_to_color[unit.provider_type]
                icon = null
                for id in unit.services
                    srv = tree_by_id[id]
                    if not srv?
                        continue
                    while srv?
                        if srv.id of srv_id_to_icon
                            icon = srv_id_to_icon[srv.id]
                            break
                        srv = srv.parent

                icon = new widgets.CanvasIcon 50
                coords = unit.location.coordinates
                popup = L.popup(closeButton: false).setContent "<strong>#{unit.name.fi}</strong>"
                marker = L.marker([coords[1], coords[0]], icon: icon)
                    .bindPopup(popup)
                    .addTo(@map)

                marker.unit = unit
                unit.marker = marker
                markers.push(marker)
                # marker.on 'click', (ev) ->
                #     marker = ev.target
                #     show_unit_details marker.unit
            return markers


    class ServiceSidebarView extends Backbone.View
        tagName: 'div'
        className: 'service-sidebar'
        events:
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
            $element = $(event.target).closest('a')
            type = $element.data('type')
            classes = "container #{ type }-open"
            $element.parent().removeClass().addClass(classes)

        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            $('.service-sidebar .container').removeClass().addClass('container')

        render: ->
            template = $.trim $('#template-service-sidebar').html()
            template_string = _.template template, {}
            @el.innerHTML = template_string

            @service_tree = new ServiceTreeView
                collection: @service_tree_collection
                app_view: @parent
                el: @$el.find('#service-tree-container')

            return @el


    class ServiceTreeView extends Backbone.View
        events:
            'click .service.has-children': 'open'
            'click .service.parent': 'open'
            'click .service.leaf': 'toggle_service'
            'click .service .show-button': 'toggle_button'

        initialize: (options) ->
            @app_view = options.app_view
            @showing = {}
            @listenTo @collection, 'sync', @render
            @collection.fetch
                data:
                    level: 0

        category_url: (id) ->
            '/#/service/' + id

        toggle_service: (event) ->
            @toggle($(event.target).find('.show-button'))

        toggle_button: (event) ->
            event.preventDefault()
            @toggle($(event.target))
            event.stopPropagation()

        toggle: ($target_element) ->
            service_id = $target_element.parent().data('service-id')
            if not @showing[service_id] == true
                $target_element.addClass 'selected'
                $target_element.text 'hide'
                @showing[service_id] = true
                @app_view.add_service_points(service_id)
            else
                delete @showing[service_id]
                $target_element.removeClass 'selected'
                $target_element.text 'show'
                @app_view.remove_service_points(service_id)

        open: (event) ->
            service_id = $(event.target).closest('li').data('service-id')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id

        set_service_tree_height: ->
            # Set the nav height according to the available screen space.
            $service_tree = @$el.find('ul.service-tree')
            service_tree_height = $(window).innerHeight() - @$el.offset().top
            $service_tree.css 'max-height': service_tree_height

        render: ->
            classes = (category) ->
                if category.attributes.children.length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                id: category.attributes.id
                name: category.attributes.name.fi
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: @showing[category.attributes.id]
            container_template = $.trim $('#template-servicetree').html()

            if not @collection.chosen_service
                heading = ''
                back = null
            else
                if @collection.chosen_service
                    heading = @collection.chosen_service.attributes.name.fi
                    back = @collection.chosen_service.attributes.parent or 'root'
                else
                    back = null
            s = _.template container_template,
                heading: heading
                back: back
                list_items: list_items
            @el.innerHTML = s
            @set_service_tree_height()
            return @el


    exports =
        AppView: AppView
        ServiceSidebarView: ServiceSidebarView
        ServiceTreeView: ServiceTreeView

    return exports
