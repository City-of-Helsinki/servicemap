requirejs.config
    baseUrl: 'vendor'
    paths:
        app: '../js'
    shim:
        'leaflet-dvf':
            deps: ['leaflet']

GEOSERVER_BASE_URL = "http://geoserver.hel.fi/geoserver/"

get_wfs = (type, args, callback) ->
    url = GEOSERVER_BASE_URL + 'wfs/'
    params =
        service: 'WFS'
        version: '1.1.0'
        request: 'GetFeature'
        typeName: type
        srsName: 'EPSG:4326'
        outputFormat: 'application/json'
    for key of args
        params[key] = args[key]
    $.getJSON url, params, callback

filter_relevant = (data) ->
    hdr = data[0]
    re = /^(\d+) (\d+)/

    out = {}
    for arr in data[1..]
        area = arr[0]
        if not area
            break
        m = area.match re
        if not m
            continue

        var_name = arr[1]
        data = []
        for x in arr[2..]
            if x == '".."'
                val = null
            else
                val = parseInt x, 10
            data.push val
        s = m[2]
        while s.length < 3
            s = '0' + s
        area_id = m[1] + ' ' + s
        if area_id not of out
            out[area_id] = {}
        out[area_id][var_name] = data

    out.header = hdr[2..]
    return out

requirejs ['app/map', 'jquery.csv', 'leaflet-dvf'], (map) ->
    stats = null
    $.ajax
        url: 'A02S_HKI_Vakiluku1962.csv'
        contentType: 'text/csv'
        success: (csv_str) ->
            csv_opts =
                separator: ';'
                delimiter: '\''
                onParseValue: (entry, state) ->
                    if entry[0] == '='
                        entry = entry[2..entry.length-2]
                    return entry
            data = $.csv.toArrays(csv_str, csv_opts)
            stats = filter_relevant data
            console.log stats

    districts = {}
    get_wfs 'hel:osaalue', {}, (data) ->
        var1_name = "0-6-vuotiaat"
        var2_name = "Väestö yhteensä"
        col_idx = stats.header.indexOf '2013'

        ###
        layer = new L.ChoroplethDataLayer data,
            locationMode: L.LocationModes.GEOJSON
            onEachRecord: (rec) ->
                console.log rec
        layer.addTo map
        ###
        feats = []
        min = max = null
        for feat in data.features
            gj = L.geoJson feat.geometry
            props = feat.properties
            id_str = props.kunta + ' ' + props.tunnus
            if id_str not of stats
                console.log "AU #{id_str} not found (#{props.nimi})"
                continue
            st = stats[id_str]
            var1 = st[var1_name][col_idx]
            var2 = st[var2_name][col_idx]
            if var1 == null or var2 == null
                val = null
            else
                val = var1 / var2
                if max == null or val > max
                    max = val
                if min == null or val < min
                    min = val
            props.val = val
            #console.log "#{id_str}: #{props.nimi}: #{var1}, #{var2}, #{var1 / var2}"
            #map.addLayer gj
            props.id = id_str
            feat.layer = gj
            feats.push feat

        console.log min
        console.log max
        func = new L.HSLSaturationFunction(new L.Point(min,0), new L.Point(max,1), outputHue: 240)
        for f in feats
            val = f.properties.val
            style =
                weight: 1
                color: "blue"

            if val != null
                style.fillColor = func.evaluate val
                style.fillOpacity = 0.5
            else
                style.fillOpacity = 0
            f.layer.setStyle style
            f.layer.addTo map
