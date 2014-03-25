define 'app/views', ['underscore', 'backbone', 'leaflet', 'app/widgets', 'app/map', 'app/models'], (_, Backbone, Leaflet, widgets, map_conf, Models) ->

    class ServiceAppView extends Backbone.View
        tagName: 'div'
        initialize: (options)->
            @service_list = new Models.ServiceList
            @service_browser = new ServiceTreeView collection: @service_list
            service_browser = @service_browser
            @service_list.fetch
                data:
                    level: 0
                success: ->
                    service_browser.render()

            @map_controls =
                title: new widgets.TitleControl()
                search: new widgets.SearchControl()
                zoom: L.control.zoom position: 'bottomright'
                scale: L.control.scale imperial: false, maxWidth: 200
                sidebar: L.control.sidebar 'sidebar', position: 'left'

        render: ->
            @map = map_conf.create_map @$el.find('#map').get(0)
            @map_controls.sidebar.on 'hide', ->
                sidebar._active_marker.closePopup()
            sidebar = @map_controls.sidebar
            @map.on 'click', (ev) ->
                sidebar.hide()
            map = @map
            _.each @map_controls,
                (control, key) -> control.addTo map

            @service_browser.map_control().addTo @map
            return this

    class ServiceTreeView extends Backbone.View
        tagName: 'div'
        className: 'service-tree'

        events:
            "click .list-group-item": "open_item"
        initialize: ->
            @listenTo @collection, "change", @render
        map_control: ->
            mc = new widgets.ServiceTreeControl @el
            return mc
        render: ->
            container_template = $.trim $('#template-tree-list-item').html()
            list_items = @collection.map (category) ->
                return _.template container_template,
                    url: '#' + category.attributes.id
                    name: category.attributes.name.fi
            element_template = $.trim $('#template-servicetree').html()
            s = _.template element_template,
                     heading: "Browse services"
                     list_items: list_items.join ''
            @$el.append $(s)

        open_item: (arg) ->
            console.log arg
    
    exports =
        ServiceTreeView: ServiceTreeView
        ServiceAppView: ServiceAppView

    return exports
