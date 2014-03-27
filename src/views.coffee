SMBACKEND_BASE_URL = sm_settings.backend_url + '/'

define 'app/views', ['underscore', 'backbone', 'leaflet', 'app/widgets', 'app/map', 'app/models'], (_, Backbone, Leaflet, widgets, map_conf, Models) ->

    class ServiceAppView extends Backbone.View
        tagName: 'div'
        initialize: (service_list, options)->
            @service_browser = new ServiceTreeView
                collection: service_list
                parent: this
            @map_controls =
                title: new widgets.TitleControl()
#                search: new widgets.SearchControl()
                zoom: L.control.zoom position: 'bottomright'
                scale: L.control.scale imperial: false, maxWidth: 200
                sidebar: L.control.sidebar 'sidebar', position: 'left'
                service_browser: @service_browser.map_control()
        service_browser: () ->
            return @service_browser
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
            return this
        add_service_points: (service_id) ->
            # todo: refactor into a model/collection
            params =
                services: service_id
                limit: 1000
            self = this
            $.getJSON SMBACKEND_BASE_URL + "unit/", params, (data) ->
                # clear_markers()
                # if division_layer
                #     map.removeLayer division_layer
                self.draw_units data.objects
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

            for unit in unit_list
                color = ptype_to_color[unit.provider_type]
                icon = null
                for srv_url in unit.services
                    arr = srv_url.split '/'
                    id = parseInt arr[arr.length-2], 10
                    srv = tree_by_id[id]
                    if not srv?
                        continue
                    while srv?
                        if srv.id of srv_id_to_icon
                            icon = srv_id_to_icon[srv.id]
                            break
                        srv = srv.parent

                icon = L.AwesomeMarkers.icon
                    icon: icon.name if icon?
                    markerColor: color
                    prefix: icon.family if icon?
                coords = unit.location.coordinates
                popup = L.popup(closeButton: false).setContent "<strong>#{unit.name.fi}</strong>"
                marker = L.marker([coords[1], coords[0]], icon: icon)
                    .bindPopup(popup)
                    .addTo(@map)

                marker.unit = unit
                unit.marker = marker
                # marker.on 'click', (ev) ->
                #     marker = ev.target
                #     show_unit_details marker.unit



    class ServiceTreeView extends Backbone.View
        tagName: 'div'
        className: 'service-tree'
        events:
            "click .service": "open"
            "click .service .show-button": "toggle"
            "mouseenter .service": (e) -> $(e.target).addClass 'hover'
            "mouseout .service": (e) -> $(e.target).removeClass 'hover'
        initialize: (options) ->
            @parent = options.parent
            @showing = {}
            @listenTo @collection, 'sync', @render
            @collection.fetch
                data:
                    level: 0
        map_control: ->
            return new widgets.ServiceTreeControl @el
            return mc
        category_url: (id) ->
            '/#/service/' + id
        toggle: (event) ->
            service_id = $(event.target).parent().data('service-id')
            if not @showing[service_id] == true
                $(event.target).addClass 'selected'
                $(event.target).text 'hide'
                @showing[service_id] = true
                @parent.add_service_points(service_id)
            else
                delete @showing[service_id]
                $(event.target).removeClass 'selected'
                $(event.target).text 'show'
        open: (event) ->
            service_id = $(event.target).data('service-id')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id
        render: ->
            @$el = $ '<div class="panel panel-default"></div>'
            self = this
            list_items = @collection.map (category) ->
                id: category.attributes.id
                name: category.attributes.name.fi
                selected: self.showing[category.attributes.id]
            container_template = $.trim $('#template-servicetree').html()

            if not @collection.chosen_service
                heading = "Browse services"
                back = null
            else
                if @collection.chosen_service
                    parent_service_url = @collection.chosen_service.attributes.parent
                    heading = @collection.chosen_service.attributes.name.fi
                    if parent_service_url
                        back = parent_service_url.replace('/v1/service/', '').replace('/', '')
                    else
                        back = 'root'
                else
                    back = null
            s = _.template container_template,
                     heading: heading
                     back: back
                     list_items: list_items
            @el.innerHTML = s
            return @el

    
    exports =
        ServiceTreeView: ServiceTreeView
        ServiceAppView: ServiceAppView

    return exports
