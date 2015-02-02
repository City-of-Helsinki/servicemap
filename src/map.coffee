define [
    'leaflet',
    'proj4leaflet',
    'underscore',
], (
    leaflet,
    p4j,
    _,
) ->

    RETINA_MODE = window.devicePixelRatio > 1

    get_max_bounds = (layer) ->
        if layer == 'ortographic'
            L.latLngBounds L.latLng(60.11322159453442, 24.839029712845157),
                L.latLng(60.30146342058585, 25.23664312801843)
        else
            L.latLngBounds L.latLng(59.5, 24.2), L.latLng(60.5, 25.5)

    wmts_path = (style, language) ->
        style_path =
            if style == 'accessible_map'
                "osm-toner/etrs_tm35fin"
            else if RETINA_MODE
                if language == 'sv'
                    "osm-sm-sv-hq/etrs_tm35fin_hq"
                else
                    "osm-sm-hq/etrs_tm35fin_hq"
            else
                if language == 'sv'
                    "osm-sm-sv/etrs_tm35fin"
                else
                    "osm-sm/etrs_tm35fin"
        path = [
            "http://144.76.78.72/mapproxy/wmts",
            style_path,
            "{z}/{x}/{y}.png"
        ]
        path.join '/'

    make_layer =
        tm35:
            crs: ->
                crs_name = 'EPSG:3067'
                proj_def = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
                bounds = L.bounds L.point(-548576, 6291456), L.point(1548576, 8388608)
                origin_nw = [bounds.min.x, bounds.max.y]
                crs_opts =
                    resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25]
                    bounds: bounds
                    transformation: new L.Transformation 1, -origin_nw[0], -1, origin_nw[1]
                new L.Proj.CRS crs_name, proj_def, crs_opts

            layer: (opts) ->
                L.tileLayer wmts_path(opts.style, opts.language),
                    maxZoom: 15
                    minZoom: 6
                    continuousWorld: true
                    tms: false

        gk25:
            crs: ->
                crs_name = 'EPSG:3879'
                proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

                bounds = [25440000, 6630000, 25571072, 6761072]
                new L.Proj.CRS.TMS crs_name, proj_def, bounds,
                    resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]

            layer: (opts) ->
                geoserver_url = (layer_name, layer_fmt) ->
                    "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{layer_name}@ETRS-GK25@#{layer_fmt}/{z}/{x}/{y}.#{layer_fmt}"
                if opts.style == 'ortographic'
                    new L.Proj.TileLayer.TMS geoserver_url("hel:orto2014", "jpg"), opts.crs,
                        maxZoom: 12
                        minZoom: 2
                        continuousWorld: true
                        tms: false
                else
                    guide_map_url = geoserver_url("hel:Karttasarja", "gif")
                    guide_map_options =
                        maxZoom: 12
                        minZoom: 2
                        continuousWorld: true
                        tms: false
                    (new L.Proj.TileLayer.TMS guide_map_url, opts.crs, guide_map_options).setOpacity 0.8

    class MapMaker
        @create_map: (dom_element, options, map_options) ->
            coordinate_system = switch options.style
                when 'guidemap' then 'gk25'
                when 'ortographic' then 'gk25'
                else 'tm35'
            layer_maker = make_layer[coordinate_system]
            crs = layer_maker.crs()
            options.crs = crs
            layer = layer_maker.layer options
            default_map_options =
                crs: crs
                continuusWorld: true
                worldCopyJump: false
                zoomControl: false
                closePopupOnClick: false
                maxBounds: get_max_bounds options.style
                layers: [layer]
            _.extend default_map_options, map_options
            map = L.map dom_element, default_map_options
            map.crs = crs
            map

    class MapUtils
        @create_position_marker: (lat_lng, accuracy, type) ->
            Z_INDEX = -1000
            switch type
                when 'detected'
                    opts =
                        icon: L.divIcon
                            iconSize: L.point 40, 40
                            iconAnchor: L.point 20, 39
                            className: 'servicemap-div-icon'
                            html: '<span class="icon-icon-you-are-here"></span'
                        zIndexOffset: Z_INDEX
                    marker = L.marker lat_lng, opts
                when 'clicked'
                    marker = L.circleMarker lat_lng,
                        color: '#666'
                        weight: 2
                        opacity: 1
                        fill: false
                        clickable: false
                        zIndexOffset: Z_INDEX
                    marker.setRadius 6
                when 'address'
                    opts =
                        zIndexOffset: Z_INDEX
                        icon: L.divIcon
                            iconSize: L.point 40, 40
                            iconAnchor: L.point 20, 39
                            className: 'servicemap-div-icon'
                            html: '<span class="icon-icon-address"></span'
                    marker = L.marker lat_lng, opts
            return marker

        @overlapping_bounding_boxes: (map) ->
            crs = map.crs
            if map._original_getBounds?
                latLngBounds = map._original_getBounds()
            else
                latLngBounds = map.getBounds()
            METER_GRID = 1000
            DEBUG_GRID = false
            ne = crs.project latLngBounds.getNorthEast()
            sw = crs.project latLngBounds.getSouthWest()
            min = x: ne.x, y: sw.y
            max = y: ne.y, x: sw.x

            snap_to_grid = (coord) ->
                parseInt(coord / METER_GRID) * METER_GRID
            coordinates = {}
            for dim in ['x', 'y']
                coordinates[dim] = coordinates[dim] or {}
                for value in [min[dim] .. max[dim]]
                    coordinates[dim][parseInt(snap_to_grid(value))] = true

            pairs = _.flatten(
                [parseInt(x), parseInt(y)] for x in _.keys(coordinates.x) for y in _.keys(coordinates.y),
                true)

            bboxes = _.map pairs, ([x, y]) -> [[x, y], [x + METER_GRID, y + METER_GRID]]
            if DEBUG_GRID
                @debug_grid.clearLayers()
                for bbox in bboxes
                    sw = crs.projection.unproject(L.point(bbox[0]...))
                    ne = crs.projection.unproject(L.point(bbox[1]...))
                    sws = [sw.lat, sw.lng].join()
                    nes = [ne.lat, ne.lng].join()
                    unless @debug_circles[sws]
                        @debug_grid.addLayer L.circle(sw, 10)
                        @debug_circles[sws] = true
                    unless @debug_circles[nes]
                        @debug_grid.addLayer L.circle(ne, 10)
                        @debug_circles[nes] = true
                    # rect = L.rectangle([sw, ne])
                    # @debug_grid.addLayer rect
            bboxes

    MapMaker: MapMaker
    MapUtils: MapUtils
