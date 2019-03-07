define (require) ->
    leaflet = require 'leaflet'
    p4j     = require 'proj4leaflet'
    _       = require 'underscore'

    sm      = require 'cs!app/base'
    dataviz = require 'cs!app/data-visualization'

    RETINA_MODE = window.devicePixelRatio > 1
    PUBLIC_TRANSIT_STOPS_MIN_ZOOM_LEVEL = 14

    getMaxBounds = (layer) ->
        L.latLngBounds(
            L.latLng(59.1, 22.964969856959073),
            L.latLng(61.5, 27.611126145397492))

    wmtsPath = (style, language) ->
        stylePath =
            if style == 'accessible_map'
                if language == 'sv'
                    "osm-sm-visual-sv/etrs_tm35fin"
                else
                    "osm-sm-visual/etrs_tm35fin"
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
            "https://geoserver.hel.fi/mapproxy/wmts",
            stylePath,
            "{z}/{x}/{y}.png"
        ]
        path.join '/'

    makeLayer =
        tm35:
            crs: ->
                crsName = 'EPSG:3067'
                projDef = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
                bounds = L.bounds L.point(-548576, 6291456), L.point(1548576, 8388608)
                originNw = [bounds.min.x, bounds.max.y]
                crsOpts =
                    resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125]
                    bounds: bounds
                    transformation: new L.Transformation 1, -originNw[0], -1, originNw[1]
                new L.Proj.CRS crsName, projDef, crsOpts

            layer: (opts) ->
                L.tileLayer wmtsPath(opts.style, opts.language),
                    maxZoom: 15
                    minZoom: 6
                    continuousWorld: true
                    tms: false

        gk25:
            crs: ->
                crsName = 'EPSG:3879'
                projDef = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

                bounds = [25440000, 6630000, 25571072, 6761072]
                new L.Proj.CRS.TMS crsName, projDef, bounds,
                    resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125]

            layer: (opts) ->
                KYMPGeoserverUrl = (layerName, layerFmt) ->
                    "https://kartta.hel.fi/ws/geoserver/gwc/service/tms/1.0.0/#{layerName}@ETRS-GK25@#{layerFmt}/{z}/{x}/{y}.#{layerFmt}"
                HSYGeoserverUrl = (layerName, layerFmt) ->
                    "https://kartta.hsy.fi/geoserver/gwc/service/wmts?layer=#{layerName}&tilematrixset=ETRS-GK25&Service=WMTS&Request=GetTile&Version=1.0.0&TileMatrix=ETRS-GK25:{z}&TileCol={x}&TileRow={y}&Format=image/#{layerFmt}"
                if opts.style == 'ortographic'
                    ortoImageUrl = HSYGeoserverUrl("taustakartat_ja_aluejaot:Ortoilmakuva_2017","jpeg")
                    ortoImageOptions =
                        maxZoom: 10
                        minZoom: 2
                        continuousWorld: false
                    new L.TileLayer ortoImageUrl, ortoImageOptions
                else
                    guideMapUrl = KYMPGeoserverUrl("avoindata:Karttasarja_PKS", "png")
                    guideMapOptions =
                        maxZoom: 10
                        minZoom: 4
                        continuousWorld: false
                        tms: true
                    (new L.Proj.TileLayer.TMS guideMapUrl, opts.crs, guideMapOptions).setOpacity 0.8

    SMap = L.Map.extend
        refitAndAddLayer: (layer) ->
            @mapState.adaptToLayer layer
            @addLayer layer
        refitAndAddMarker: (marker) ->
            @mapState.adaptToLatLngs [marker.getLatLng()]
            @addLayer marker
        adaptToLatLngs: (latLngs) ->
            @mapState.adaptToLatLngs latLngs
        setMapView: (viewOptions) ->
            @mapState.setMapView viewOptions
        adapt: ->
            @mapState.adaptToBounds null
        zoomTo: (level) ->
            @mapState.zoomTo(level)

    class MapMaker
        @makeBackgroundLayer: (options) ->
            coordinateSystem = switch options.style
                when 'guidemap' then 'gk25'
                when 'ortographic' then 'gk25'
                else 'tm35'
            layerMaker = makeLayer[coordinateSystem]
            crs = layerMaker.crs()
            options.crs = crs
            tileLayer = layerMaker.layer options
            tileLayer.on 'tileload', (e) =>
                e.tile.setAttribute 'alt', ''
            layer: tileLayer
            crs: crs
        @createMap: (domElement, options, mapOptions, mapState) ->
            {layer: layer, crs: crs} = MapMaker.makeBackgroundLayer options
            defaultMapOptions =
                crs: crs
                continuusWorld: true
                worldCopyJump: false
                zoomControl: false
                closePopupOnClick: false
                maxBounds: getMaxBounds options.style
                layers: [layer]
                preferCanvas: true
            _.extend defaultMapOptions, mapOptions
            map = new SMap domElement, defaultMapOptions
            mapState?.setMap map
            map.crs = crs
            map._baseLayer = layer
            map

    class MapUtils
        @createPositionMarker: (latLng, accuracy, type, opts) ->
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
                    marker = L.marker latLng, opts
                when 'clicked'
                    marker = L.circleMarker latLng,
                        color: '#666'
                        weight: 2
                        opacity: 1
                        fill: false
                        clickable: if opts?.clickable? then opts.clickable else false
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
                    marker = L.marker latLng, opts
            return marker

        @overlappingBoundingBoxes: (map) ->
            crs = map.crs
            if map._originalGetBounds?
                latLngBounds = map._originalGetBounds()
            else
                latLngBounds = map.getBounds()
            METER_GRID = 1000
            DEBUG_GRID = false
            ne = crs.project latLngBounds.getNorthEast()
            sw = crs.project latLngBounds.getSouthWest()
            min = x: ne.x, y: sw.y
            max = y: ne.y, x: sw.x

            if ((Math.abs(min.x - max.x) / METER_GRID) > 4 or
               (Math.abs(max.y - min.y) / METER_GRID) > 4)
                # The idea of the grids is to maximize cache hits. But
                # if the original bounding box spans too many grid
                # elements, it defeats the purpose, so disable
                # gridding in that case.
                return [[[min.x, min.y],[max.x, max.y]]]


            snapToGrid = (coord) ->
                parseInt(coord / METER_GRID) * METER_GRID
            coordinates = {}
            for dim in ['x', 'y']
                coordinates[dim] = coordinates[dim] or {}
                for value in [min[dim] .. max[dim]]
                    coordinates[dim][parseInt(snapToGrid(value))] = true

            pairs = _.flatten(
                [parseInt(x), parseInt(y)] for x in _.keys(coordinates.x) for y in _.keys(coordinates.y),
                true)

            bboxes = _.map pairs, ([x, y]) -> [[x, y], [x + METER_GRID, y + METER_GRID]]
            if DEBUG_GRID
                @debugGrid.clearLayers()
                for bbox in bboxes
                    sw = crs.projection.unproject(L.point(bbox[0]...))
                    ne = crs.projection.unproject(L.point(bbox[1]...))
                    sws = [sw.lat, sw.lng].join()
                    nes = [ne.lat, ne.lng].join()
                    unless @debugCircles[sws]
                        @debugGrid.addLayer L.circle(sw, 10)
                        @debugCircles[sws] = true
                    unless @debugCircles[nes]
                        @debugGrid.addLayer L.circle(ne, 10)
                        @debugCircles[nes] = true
                    # rect = L.rectangle([sw, ne])
                    # @debugGrid.addLayer rect
            bboxes

        @latLngFromGeojson: (object) ->
            L.latLng object?.get('location')?.coordinates?.slice(0).reverse()

        @getZoomlevelToShowPublicTransitStops: -> PUBLIC_TRANSIT_STOPS_MIN_ZOOM_LEVEL

        @getZoomlevelToShowAllMarkers: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                return 8
            else if layer == 'ortographic'
                return 8
            else
                return 14

        @createHeatmapLayer: (id) ->
            ###L.tileLayer.wms "http://geoserver.hel.fi/geoserver/popdensity/wms",
                layers: id,
                format: 'image/png',
                transparent: true###
                # TODO: select data set with style: parameter
            L.tileLayer dataviz.heatmapLayerPath(id), bounds: [[60.09781624004459, 24.502779123289532],
                [60.39870150471201, 25.247861779136283]]

    makeDistanceComparator = (p13n) =>
        createFrom = (position) =>
            (obj) =>
                [a, b] = [MapUtils.latLngFromGeojson(position), MapUtils.latLngFromGeojson(obj)]
                result = a.distanceTo b
                result
        position = p13n.getLastPosition()
        if position?
            createFrom position

    MapMaker: MapMaker
    MapUtils: MapUtils
    makeDistanceComparator: makeDistanceComparator
