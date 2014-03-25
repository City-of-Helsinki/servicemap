define "app/widgets", ['leaflet', 'servicetree', 'underscore', 'jquery', 'backbone'], (leaflet, service_tree, _, $, Backbone) ->


    TitleControl: L.Control.extend
        options:
            position: 'topleft'
        onAdd: (map) ->
            # create the control container with a particular class name
            container = L.DomUtil.create 'div', 'title-control'
            logo = L.DomUtil.create 'h2', 'title-logo', container
            logo.innerHTML = '[LOGO] Service Map'
            return container

    SearchControl: L.Control.extend
        options:
            position: 'topright'
        onAdd: (map) ->
            $container = $("<div id='search' />")
            $el = $("<input type='text' name='query' class='form-control'>")
            $el.css
                width: '250px'
            $container.append $el
            return $container.get(0)

    ServiceTreeControl: L.Control.extend
        initialize: (element, options) ->
            L.Util.setOptions this, options
            this.element = element
        options:
            position: 'topleft'
        onAdd: (map) ->
            return this.element

