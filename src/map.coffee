define "app/map", ['leaflet', 'proj4leaflet', 'leaflet.awesome-markers', 'backbone', 'backbone.marionette', 'app/widgets'], (leaflet, p4j, awesome_markers, Backbone, Marionette, widgets) ->
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
                minZoom: 0
                continuousWorld: true
                tms: false

            map_layer = new L.TileLayer url, opts

            layer_control = null

        map = new L.Map el,
            crs: crs
            continuusWorld: true
            worldCopyJump: false
            zoomControl: false
            layers: [map_layer]

        map.setView [60.171944, 24.941389], 10
        return map

    class MapView extends Backbone.Marionette.View
        tagName: 'div'
        render: ->
            @$el.attr 'id', 'map'
            @
        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            @map = create_map @$el.get 0
            @map.on 'zoomend', (e) -> console.log "zoomend"
            L.control.zoom(
                position: 'bottomright'
                zoomInText: '<span class="icon-icon-zoom-in"></span>'
                zoomOutText: '<span class="icon-icon-zoom-out"></span>').addTo @map

    return MapView
