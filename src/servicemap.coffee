console.log "servicemap here"
requirejs.config
    baseUrl: 'vendor'
    paths:
        app: '../js'

crs_name = 'EPSG:3879'
proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

requirejs ['proj4leaflet'], (p4j) ->
    console.log "all loaded"
    bounds = [2.547210017612655e7, 6654072.819370746, 2.553763617612655e7, 6719608.819370746]
    crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
        resolutions: [16, 8, 4, 2, 1]
    map = new L.Map 'map',
        crs: crs
        continuusWorld: true
        worldCopyJump: false
    map.setView [60.171944, 24.941389], 8
    map.addLayer new L.Proj.TileLayer.TMS 'http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/hel%3AOpPks_4m@ETRS-GK25@jpg/{z}/{x}/{y}.jpg', crs,
        maxZoom: 10
        minZoom: 0
        continuousWorld: true
        attribution: ''
