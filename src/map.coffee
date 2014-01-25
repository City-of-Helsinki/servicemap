define "app/map", ['leaflet', 'proj4leaflet', 'leaflet.awesome-markers'], (leaflet, p4j) ->
    crs_name = 'EPSG:3879'
    proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

    bounds = [25440000, 6630000, 25571072, 6761072]
    crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
        resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]
    map = new L.Map 'map',
        crs: crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: false
    map.setView [60.171944, 24.941389], 5

    L.control.scale(imperial: false, maxWidth: 200).addTo map

    layer = new L.Proj.TileLayer.TMS 'http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/hel:Opaskartta@ETRS-GK25@gif/{z}/{x}/{y}.gif', crs,
        maxZoom: 10
        minZoom: 2
        continuousWorld: true
        tms: false
    map.addLayer layer

    return map
