requirejs.config
    baseUrl: 'vendor'
    paths:
        app: '../js'

crs_name = 'EPSG:3879'
proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

SearchControl = L.Control.extend
    options: {
        position: 'topleft'
    },

    onAdd: (map) ->
        $container = $("<div id='search'>")
        $el = $("<input type='text' name='query' class='form-control'>")
        $el.css
            width: '250px'
        $container.append $el
        return $container.get(0)

requirejs ['proj4leaflet', 'lunr', 'servicetree', 'typeahead'], (p4j) ->
    bounds = [2.547210017612655e7, 6654072.819370746, 2.553763617612655e7, 6719608.819370746]
    crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
        resolutions: [1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1]
    map = new L.Map 'map',
        crs: crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: false
    map.setView [60.171944, 24.941389], 8

    layer = new L.Proj.TileLayer.TMS 'http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/hel:Palvelukartta@ETRS-GK25@gif/{z}/{x}/{y}.gif', crs,
        maxZoom: 10
        minZoom: 5
        continuousWorld: true
        tms: false
    map.addLayer layer
    new SearchControl().addTo(map)

    map.on 'mousemove', (e) ->
        ll = e.latlng
        $el = $("#info")
        $el.html "<div>#{ll.lat}, #{ll.lng}</div><div>#{map.getZoom()}</div>"

    index = lunr ->
        @field 'name_fi'
        @ref 'id'
        @pipeline = new lunr.Pipeline()

    tree_by_id = {}
    process_tree = (tree, parent, lunr) ->
        for item in tree
            item.parent = parent
            if lunr
                index.add item
            tree_by_id[item.id] = item
        for item in tree
            if item.children
                process_tree item.children, item, lunr

    index_str = localStorage.getItem 'servicemap_lun_index'
    if index_str
        console.log "loading index"
        index_json = JSON.parse index_str
        index = lunr.Index.load index_json
        process_tree SERVICE_TREE, null, false
        console.log "done"
    else
        console.log "adding to index"
        process_tree SERVICE_TREE, null, true
        console.log "done"
        localStorage.setItem 'servicemap_lun_index', JSON.stringify index.toJSON()

    $("#search input").typeahead
        sections: [
            name: 'services'
            source: (query, process) ->
                res_list = index.search query
                output = []
                for res in res_list[0..20]
                    service = tree_by_id[parseInt(res.ref, 10)]
                    output.push id: service.id, value: service.name_fi
                process output
            highlight: true
        ]

    markers = []
    $("#search input").on 'typeahead:selected', (ev, item) ->
        center = map.getCenter()
        ne = map.getBounds().getNorthEast()
        distance = Math.round(ne.distanceTo center)
        url = "http://www.hel.fi/palvelukarttaws/rest/v2/unit/?service=#{item.id}&lat=#{center.lat}&lon=#{center.lng}&distance=#{distance}&callback=?"
        $.getJSON url, (data) ->
            console.log data
            for m in markers
                map.removeLayer m
            for unit in data
                marker = L.marker([unit.latitude, unit.longitude]).addTo map
                markers.push marker

    window.index = index
    ###
