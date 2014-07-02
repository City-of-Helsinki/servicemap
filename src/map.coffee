define "app/map", ['leaflet', 'proj4leaflet', 'leaflet.awesome-markers', 'backbone', 'backbone.marionette', 'leaflet.markercluster', 'app/widgets', 'app/models', 'app/p13n'], (leaflet, p4j, awesome_markers, Backbone, Marionette, markercluster, widgets, models, p13n) ->
    create_map = (el) ->
        if false
            crs_name = 'EPSG:3879'
            proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

            bounds = [25440000, 6630000, 25571072, 6761072]
            crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
                resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]

            geoserver_url = (layer_name, layer_fmt) ->
                "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{layer_name}@ETRS-GK25@#{layer_fmt}/{z}/{x}/{y}.#{layer_fmt}"

            orto_layer = new L.Proj.TileLayer.TMS geoserver_url("hel:orto2012", "jpg"), crs,
                maxZoom: 12
                minZoom: 2
                continuousWorld: true
                tms: false

            guide_map_url = geoserver_url("hel:Opaskartta", "gif")
            guide_map_options =
                maxZoom: 12
                minZoom: 2
                continuousWorld: true
                tms: false

            map_layer = new L.Proj.TileLayer.TMS guide_map_url, crs, guide_map_options
            map_layer.setOpacity 0.8

            layer_control = L.control.layers
                'Opaskartta': map_layer
                'Ilmakuva': orto_layer
        else
            crs_name = 'EPSG:3067'
            proj_def = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

            bounds = L.bounds L.point(-548576, 6291456), L.point(1548576, 8388608)
            origin_nw = [bounds.min.x, bounds.max.y]
            crs_opts = 
                resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25]
                bounds: bounds
                transformation: new L.Transformation 1, -origin_nw[0], -1, origin_nw[1]

            crs = new L.Proj.CRS crs_name, proj_def, crs_opts
            url = "http://geoserver.hel.fi/mapproxy/wmts/osm-sm/etrs_tm35fin/{z}/{x}/{y}.png"
            opts =
                maxZoom: 15
                minZoom: 8
                continuousWorld: true
                tms: false

            map_layer = new L.TileLayer url, opts

            layer_control = null

        map = new L.Map el,
            crs: crs
            continuusWorld: true
            worldCopyJump: false
            zoomControl: false
            maxBounds: L.latLngBounds L.latLng(60, 24.2), L.latLng(60.5, 25.5)
            layers: [map_layer]

        window.debug_map = map
        map.setView [60.171944, 24.941389], 10
        return map

    MAX_AUTO_ZOOM = 12
    ICON_SIZE = 40
    if get_ie_version() and get_ie_version() < 9
        ICON_SIZE *= .8
    MARKER_POINT_VARIANT = false

    class MapView extends Backbone.Marionette.View
        tagName: 'div'
        initialize: (opts) ->
            @navigation_layout = opts.navigation_layout
            @units = opts.units
            @selected_services = opts.services
            @search_results = opts.search_results
            @selected_units = opts.selected_units
            #@listenTo @units, 'add', @draw_units
            @listenTo @units, 'finished', =>
            # Triggered when all of the
            # pages of units have been fetched.
                unless @selected_services.isEmpty()
                    @draw_units @units
                    @refit_bounds()
            @listenTo @units, 'batch-remove', @remove_units
            @listenTo @units, 'remove', @remove_unit
            @listenTo @units, 'reset', =>
                @all_markers.clearLayers()
                @units.each (unit) => @draw_unit(unit)
                unless @units.isEmpty()
                    @refit_bounds()
            @listenTo @selected_units, 'reset', (units, options) ->
                if units.isEmpty()
                    return
                previous_units = options?.previousModels
                if previous_units? and previous_units.length > 0
                    previous_unit = previous_units[0]
                    $(previous_unit.marker?._popup._wrapper).removeClass 'selected'
                    previous_unit.marker?.closePopup()
                unit = units.first()
                if not unit.marker?
                    @draw_unit(unit)
                    @refit_bounds(true)
                @highlight_selected_marker unit.marker

            @listenTo p13n, 'position', @handle_user_position

        handle_user_position: (pos) ->
            if not @_isShown
                return
            lat_lng = L.latLng [pos.coords.latitude, pos.coords.longitude]
            accuracy = pos.coords.accuracy
            radius = 4
            if not @user_position_markers?
                opts =
                    weight: 0
                accuracy_marker = L.circle lat_lng, accuracy, opts
                @map.addLayer accuracy_marker
                opts =
                    color: '#ff0000'
                    radius: radius
                marker = L.circleMarker lat_lng, opts
                @map.addLayer marker
                @user_position_markers =
                    accuracy: accuracy_marker
                    position: marker
            else
                pm = @user_position_markers
                pm.accuracy.setLatLng lat_lng
                pm.accuracy.setRadius radius
                pm.position.setLatLng lat_lng

        render: ->
            @$el.attr 'id', 'map'
        width: ->
            @$el.width()
        height: ->
            @$el.height()
        to_coordinates: (windowCoordinates) ->
            @map.layerPointToLatLng(@map.containerPointToLayerPoint(windowCoordinates))

        remove_units: (options) ->
            @all_markers.clearLayers()
            @draw_units @units

        remove_unit: (unit, units, options) ->
            if unit.marker?
                @all_markers.removeLayer unit.marker
                delete unit.marker

        create_icon: (unit, services) ->
            color = app.color_matcher.unit_color(unit) or 'rgb(255, 255, 255)'
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasIcon
            else
                ctor = widgets.PlantCanvasIcon
            new ctor ICON_SIZE, color, unit.id

        create_cluster_icon: (cluster) ->
            count = cluster.getChildCount()
            service_collection = new models.ServiceList()
            if not @selected_services.isEmpty()
                service_collection.add @selected_services.last()
            markers = cluster.getAllChildMarkers()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                unless @selected_services.isEmpty()
                    service = @selected_services.find (s) =>
                        s.get('root') in marker.unit.get('root_services')
                else
                    service = new models.Service
                        id: marker.unit.get('root_services')[0]
                        root: marker.unit.get('root_services')[0]
                service_collection.add service

            colors = service_collection.map (service) =>
                app.color_matcher.service_color(service)
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            new ctor count, ICON_SIZE, colors, service_collection.first().id

        create_marker: (unit) ->
            location = unit.get 'location'
            coords = location.coordinates
            html_content = "<div class='unit-name'>#{unit.get_text 'name'}</div>"
            popup = new widgets.LeftAlignedPopup
                closeButton: false
                autoPan: false
                zoomAnimation: false
                minWidth: 500
            popup.setContent html_content
            icon = @create_icon unit, @selected_services
            marker = L.marker [coords[1], coords[0]],
                icon: icon

            marker.bindPopup(popup)

        highlight_selected_marker: (marker) ->
            popup = marker.getPopup()
            popup.setLatLng marker.getLatLng()
            popup.addTo @map
            $(marker?._popup._wrapper).addClass 'selected'

        select_marker: (event) ->
            marker = event.target
            unit = marker.unit
            app.commands.execute 'selectUnit', unit
            #@highlight_selected_marker marker

        draw_units: (units) ->
            units_with_location = units.filter (u) =>
                u.get('location')?
            markers = units_with_location.map (unit) =>
                    marker = @create_marker unit
                    marker.unit = unit
                    unit.marker = marker
                    @listenTo marker, 'click', @select_marker
                    marker.on 'mouseover', (event) -> event.target.openPopup()
                    return marker
            @all_markers.addLayers markers

        draw_unit: (unit, units, options) ->
            location = unit.get('location')
            if location?
                marker = @create_marker unit
                @all_markers.addLayer marker
                marker.unit = unit
                unit.marker = marker
                @listenTo marker, 'click', @select_marker
                marker.on 'mouseover', (event) ->
                    event.target.openPopup()

        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            @map = create_map @$el.get 0
            @all_markers = new L.MarkerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: 30
                iconCreateFunction: (cluster) =>
                    @create_cluster_icon(cluster)

            L.control.zoom(
                position: 'bottomright'
                zoomInText: '<span class="icon-icon-zoom-in"></span>'
                zoomOutText: '<span class="icon-icon-zoom-out"></span>').addTo @map
            @all_markers.addTo @map

        effective_horizontal_center: ->
            sidebar_edge = @navigation_layout.right_edge_coordinate()
            sidebar_edge + (@width() - sidebar_edge) / 2
        effective_center: ->
            [ Math.round(@effective_horizontal_center()),
              Math.round(@height() / 2) ]
        effective_padding_top_left: (pad) ->
            sidebar_edge = @navigation_layout.right_edge_coordinate()
            [sidebar_edge, pad]

        refit_bounds: (single) ->
            marker_bounds = @all_markers.getBounds()
            unless marker_bounds.isValid()
                return
            if single or not @map.getBounds().intersects marker_bounds
                opts =
                    paddingTopLeft: @effective_padding_top_left(100)
                    maxZoom: MAX_AUTO_ZOOM
                @map.fitBounds marker_bounds, opts

    return MapView
