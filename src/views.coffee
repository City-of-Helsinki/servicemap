define 'app/views', ['underscore', 'backbone', 'leaflet', 'app/widgets', 'app/map', 'app/models'], (_, Backbone, Leaflet, widgets, map_conf, Models) ->

    class ServiceAppView extends Backbone.View
        tagName: 'div'
        initialize: (service_list, options)->
            @service_browser = new ServiceTreeView collection: service_list
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

    class ServiceTreeView extends Backbone.View
        tagName: 'div'
        className: 'service-tree'
        initialize: ->
            @listenTo @collection, 'sync', @render
            @collection.fetch()
        map_control: ->
            return new widgets.ServiceTreeControl @el
            return mc
        render: ->
            element_template = $.trim $('#template-tree-list-item').html()
            list_items = @collection.map (category) ->
                return _.template element_template,
                    url: '/#/service/' + category.attributes.id
                    name: category.attributes.name.fi

            container_template = $.trim $('#template-servicetree').html()
            if @collection.level == 0
                heading = "Browse services"
            else
                heading = @collection.parent_service.attributes.name.fi
            s = _.template container_template,
                     heading: heading
                     list_items: list_items.join ''
            @$el.html s
    
    exports =
        ServiceTreeView: ServiceTreeView
        ServiceAppView: ServiceAppView

    return exports
