define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'app/p13n', 'app/widgets', 'app/jade', 'app/models'], (_, Backbone, Marionette, Leaflet, i18n, p13n, widgets, jade, models) ->
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

        render: ->
            return this
        remember_markers: (service_id, markers) ->
            @current_markers[service_id] = markers
        remove_service_points: (service_id) ->
            _.each @current_markers[service_id], (marker) =>
                @map.removeLayer marker
            delete @current_markers[service_id]

        add_service_points: (service_id) ->
            unit_list = new models.UnitList()
            unit_list.fetch
                data:
                    service: service_id
                    page_size: 1000
                success: =>
                    markers = @draw_units unit_list
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
            unit_list.each (unit) =>
                #color = ptype_to_color[unit.provider_type]
                icon = new widgets.CanvasIcon 50
                coords = unit.get('location').coordinates
                popup = L.popup(closeButton: false).setContent "<strong>#{unit.get_text 'name'}</strong>"
                marker = L.marker([coords[1], coords[0]], icon: icon)
                    .bindPopup(popup)
                    .addTo(@map)

                marker.unit = unit
                unit.marker = marker
                markers.push marker
                marker.on 'click', (event) =>
                    marker = event.target
                    @service_sidebar.show_details marker.unit

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

        switch_content: (content_type) ->
            classes = "container #{ content_type }-open"
            @$el.find('.container').removeClass().addClass(classes)

        open: (event) ->
            event.preventDefault()
            $element = $(event.target).closest('a')
            type = $element.data('type')
            @switch_content type

        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            $('.service-sidebar .container').removeClass().addClass('container')

        show_details: (unit) ->
            @$el.find('.container').addClass('details-open')
            @details_view.unit = unit
            @details_view.render()

        hide_details: ->
            @$el.find('.container').removeClass('details-open')

        set_contents_height: =>
            # Set the contents height according to the available screen space.
            $contents = @$el.find('.contents')
            contents_height = $(window).innerHeight() - @$el.outerHeight(true)
            $contents.css 'max-height': contents_height

        render: ->
            s1 = i18n.t 'sidebar.search'
            if not s1
                console.log i18n
                throw 'i18n not initialized'
            template_string = jade.template 'service-sidebar'
            @el.innerHTML = template_string

            @service_tree = new ServiceTreeView
                collection: @service_tree_collection
                app_view: @parent
                el: @$el.find('#service-tree-container')

            @details_view = new DetailsView
                el: @$el.find('#details-view-container')
                parent: @

            # The element height is not yet set in the DOM so we have to use this
            # ugly hack here.
            # TODO: Get rid of this!
            _.delay @set_contents_height, 10

            return @el


    class DetailsView extends Backbone.View
        events:
            'click .back-button': 'close'

        initialize: (options) ->
            @parent = options.parent
            @template = $.trim $('#template-details-view').html()
            @unit = null

        close: (event) ->
            event.preventDefault()
            @parent.hide_details()

        render: ->
            data = @unit.toJSON()
            template_string = jade.template 'details', data
            @el.innerHTML = template_string

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
                $target_element.text i18n.t 'sidebar.hide'
                @showing[service_id] = true
                @app_view.add_service_points(service_id)
            else
                delete @showing[service_id]
                $target_element.removeClass 'selected'
                $target_element.text i18n.t 'sidebar.show'
                @app_view.remove_service_points(service_id)

        open: (event) ->
            service_id = $(event.target).closest('li').data('service-id')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id

        render: ->
            classes = (category) ->
                if category.attributes.children.length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                id: category.get 'id'
                name: category.get_text 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: @showing[category.attributes.id]

            if not @collection.chosen_service
                heading = ''
                back = null
            else
                if @collection.chosen_service
                    heading = @collection.chosen_service.get_text 'name'
                    back = @collection.chosen_service.get('parent') or 'root'
                else
                    back = null
            data =
                heading: heading
                back: back
                list_items: list_items
            s = jade.template 'service-tree', data
            @el.innerHTML = s
            return @el


    exports =
        AppView: AppView
        ServiceSidebarView: ServiceSidebarView
        ServiceTreeView: ServiceTreeView

    return exports
