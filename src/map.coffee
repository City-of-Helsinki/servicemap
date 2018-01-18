define (require) ->
    leaflet = require 'leaflet'
    p4j     = require 'proj4leaflet'
    _       = require 'underscore'

    sm      = require 'cs!app/base'
    dataviz = require 'cs!app/data-visualization'

    RETINA_MODE = window.devicePixelRatio > 1

    getMaxBounds = (layer) ->
        L.latLngBounds L.latLng(59.4, 23.8), L.latLng(61.5, 25.8)

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
            crs: (opts) ->
                crsName = 'EPSG:3879'
                projDef = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
                if opts.style == 'guidemap'
                    bounds = L.bounds L.point(25440000, 6630000), L.point(25571072, 6761072)
                    originNw = [bounds.min.x, bounds.max.y]
                    crsOpts =
                        resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125]
                        bounds: bounds
                        transformation: new L.Transformation 1, -originNw[0], -1, originNw[1]
                    new L.Proj.CRS crsName, projDef, crsOpts
                else if opts.style == 'ortographic'
                    bounds = L.bounds L.point(25472049.6714, 6647388.112726935), L.point(25527950.3286, 6759189.4270052845)
                    originNw = [bounds.min.x, bounds.max.y]
                    crsOpts =
                        resolutions: [218.36194194990094, 109.18097097495047, 54.590485487475235, 27.295242743737617, 13.647621371868809, 6.823810685934404, 3.411905342967202, 1.705952671483601, 0.8529763357418005, 0.4264881678709003, 0.2132440839354501, 0.1066220419677251, 0.0533110209838625]
                        bounds: bounds
                new L.Proj.CRS crsName, projDef, crsOpts


# KVP service=WMTS&request=GetTile&version=1.0.0&
# layer=etopo2&style=default&format=image/png&TileMatrixSet=EPSG:3879
# TileMatrix=10m&TileRow=1&TileCol=3
#
#
# HSY
# <TileSet><SRS>EPSG:3879</SRS><BoundingBox SRS="EPSG:3879"
#  minx="2.5472049671430413E7"
#  miny="6647388.112726935"
#  maxx="2.5527950328569587E7"
#  maxy="6759189.4270052845"
# <Resolutions>
# 218.36194194990094
# 109.18097097495047
# 54.590485487475235
# 27.295242743737617
# 13.647621371868809
# 6.823810685934404
# 3.411905342967202
# 1.705952671483601
# 0.8529763357418005
# 0.4264881678709003
# 0.2132440839354501
# 0.1066220419677251
# 0.0533110209838625
# <Width>256</Width><Height>256</Height>
# <Format>image/png</Format>
# <Layers>taustakartat_ja_aluejaot:Ortoilmakuva_2017</Layers><Styles/></TileSet>
            layer: (opts) ->
                if opts.style == 'ortographic'
                    new L.TileLayer "https://kartta.hsy.fi/geoserver/gwc/service/wmts?request=GetTile&version=1.0.0&layer=taustakartat_ja_aluejaot:Ortoilmakuva_2017&style=raster&format=image%2Fjpeg&TileMatrixSet=EPSG:3879&TileMatrix=EPSG:3879:{z}&TileRow={y}&TileCol={x}",
                        maxZoom: 10
                        minZoom: 2
                        continuousWorld: true
                        tms: false
                else
                    new L.TileLayer "https://kartta.hel.fi/ws/geoserver/gwc/service/wmts?request=GetTile&version=1.0.0&layer=avoindata:Karttasarja_PKS&style=default&format=image%2Fgif&TileMatrixSet=ETRS-GK25&TileMatrix=ETRS-GK25:{z}&TileRow={y}&TileCol={x}",
                        maxZoom: 11
                        minZoom: 2
                        continuousWorld: true
                        tms: false

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

    class MapMaker
        @makeBackgroundLayer: (options) ->
            coordinateSystem = switch options.style
                when 'guidemap' then 'gk25'
                when 'ortographic' then 'gk25'
                else 'tm35'
            layerMaker = makeLayer[coordinateSystem]
            crs = layerMaker.crs options
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
