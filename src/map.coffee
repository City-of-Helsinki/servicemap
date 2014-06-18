define "app/map", ['leaflet', 'proj4leaflet', 'leaflet.awesome-markers', 'backbone', 'backbone.marionette', 'app/widgets', 'app/color', 'leaflet.markercluster'], (leaflet, p4j, awesome_markers, Backbone, Marionette, widgets, colors) ->
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
    ICON_SIZE = 50
    if get_ie_version() and get_ie_version() < 9
        ICON_SIZE *= .8

    class MapView extends Backbone.Marionette.View
        tagName: 'div'
        initialize: (opts) ->
            @navigation_layout = opts.navigation_layout
            @units = opts.units
            @selected_services = opts.services
            @selected_units = opts.selected_units
            @listenTo @units, 'add', @draw_unit
            @listenTo @units, 'finished', =>
                # Triggered when all of the
                # pages of units have been fetched.
                @refit_bounds()
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

        render: ->
            @$el.attr 'id', 'map'
        width: ->
            @$el.width()
        height: ->
            @$el.height()
        to_coordinates: (windowCoordinates) ->
            @map.layerPointToLatLng(@map.containerPointToLayerPoint(windowCoordinates))

        remove_unit: (unit, units, options) ->
            @all_markers.removeLayer unit.marker
            delete unit.marker

        create_icon: (unit, services) ->
            color = colors.unit_color(unit, services) or 'rgb(255, 255, 255)'
            new widgets.CanvasIcon ICON_SIZE, color, unit.id

        create_cluster_icon: (services, count, bounds) ->
            # todo: use getBounds to estimate
            # spread of berries ...
            service = services.last()
            color = colors.service_color(service)
            new widgets.CanvasClusterIcon count, ICON_SIZE, color, service.id

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
            marker = L.marker [coords[1], coords[0]],
                icon: @create_icon unit, @selected_services
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
            #@all_markers = L.featureGroup()
            @all_markers = new L.MarkerClusterGroup
                showCoverageOnHover: false            
                iconCreateFunction: (cluster) =>
                    @create_cluster_icon(
                        @selected_services, cluster.getChildCount(), cluster.getBounds())

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
            if single or not @map.getBounds().intersects marker_bounds
                opts =
                    paddingTopLeft: @effective_padding_top_left(100)
                    maxZoom: MAX_AUTO_ZOOM
                @map.fitBounds marker_bounds, opts

    return MapView
