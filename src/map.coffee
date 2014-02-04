define "app/map", ['leaflet', 'proj4leaflet', 'leaflet.awesome-markers'], (leaflet, p4j) ->
    crs_name = 'EPSG:3879'
    proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

    bounds = [25440000, 6630000, 25571072, 6761072]
    crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
        resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]

    geoserver_url = (layer_name, layer_fmt) ->
        "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{layer_name}@ETRS-GK25@#{layer_fmt}/{z}/{x}/{y}.#{layer_fmt}"

    orto_layer = new L.Proj.TileLayer.TMS geoserver_url("hel:orto2013", "jpg"), crs,
        maxZoom: 11
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

    map = new L.Map 'map',
        crs: crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: true
        layers: [map_layer]
    map.setView [60.171944, 24.941389], 5

    L.control.scale(imperial: false, maxWidth: 200).addTo map

    layer_control = L.control.layers
        'Opaskartta': map_layer
        'Ilmakuva': orto_layer

    return map: map, layer_control: layer_control
