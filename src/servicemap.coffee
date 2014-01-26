requirejs.config
    baseUrl: 'vendor'
    shim:
        underscore:
            exports: '_'
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'backbone-tastypie':
            deps: ['backbone']
        typeahead:
            deps: ['jquery']
        'leaflet.awesome-markers':
            deps: ['leaflet']
        'L.Control.Sidebar':
            deps: ['leaflet']
    paths:
        app: '../js'

SMBACKEND_BASE_URL = "http://localhost:8000/v1/"

requirejs ['app/map', 'app/models', 'jquery', 'lunr', 'servicetree', 'typeahead', 'L.Control.Sidebar'], (map, Models, $) ->
    dept_list = new Models.DepartmentList
    dept_list.fetch
        data:
            limit: 1000

    org_list = new Models.OrganizationList
    org_list.fetch
        data:
            limit: 1000

    window.dept_list = dept_list
    window.org_list = org_list

    SearchControl = L.Control.extend
        options:
            position: 'topright'

        onAdd: (map) ->
            $container = $("<div id='search' />")
            $el = $("<input type='text' name='query' class='form-control'>")
            $el.css
                width: '250px'
            $container.append $el
            return $container.get(0)

    new SearchControl().addTo(map)

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
    window.tree_by_id = tree_by_id

    index_str = localStorage.getItem 'servicemap_lun_index'
    if index_str
        index_json = JSON.parse index_str
        index = lunr.Index.load index_json
        process_tree SERVICE_TREE, null, false
    else
        process_tree SERVICE_TREE, null, true
        localStorage.setItem 'servicemap_lun_index', JSON.stringify index.toJSON()

    sections = [
        {
            name: 'services'
            source: (query, process) ->
                res_list = index.search query
                output = []
                for res in res_list[0..20]
                    service = tree_by_id[parseInt(res.ref, 10)]
                    output.push id: service.id, value: service.name_fi, service: service
                process output
            highlight: true
        }, {
            name: 'areas'
            source: (query, process) ->
                params =
                    parent__name: 'Helsinki'
                    type__type__in: ['neighborhood', 'district'].join ','
                    input: query
                $.getJSON SMBACKEND_BASE_URL + 'administrative_division/', params, (data) ->
                    objs = data.objects
                    output = []
                    for obj in objs
                        output.push id: obj.id, value: obj.name.fi, division: obj
                    process output
            highlight: true
        }
    ]

    $("#search input").typeahead {highlight: true}, sections[0], sections[1]

    show_unit_details = (unit) ->
        html = "<h3>#{unit.name.fi}</h3>"

        if unit.department
            dept = dept_list.get unit.department
            html += "<div class='department'>#{dept.get('name').fi}</div><hr/>"

        addr = null
        if unit.street_address
            addr = unit.street_address.fi
        if unit.picture_url
            html += "<img src=\"#{unit.picture_url}\" width=400>"

        if unit.description? and unit.description.fi?
            html += "<p>#{unit.description.fi}</p><hr/>"

        html += "<h4>Palvelut</h4>"
        srv_html = "<ul>"
        for srv_url in unit.services
            arr = srv_url.split '/'
            id = parseInt arr[arr.length-2], 10
            srv = tree_by_id[id]
            if not srv?
                continue
            srv_html += "<li>#{srv.name_fi} (#{id})</li>"
        srv_html += "</ul>"
        html += srv_html
        $("#sidebar").html html
        sidebar.show()

    draw_units = (unit_list) ->
        # 100 = ei tiedossa, 101 = kunnallinen, 102 = kunnan tukema, 103 = kuntayhtymä,
        # 104 = valtio, 105 = yksityinen
        ptype_to_color =
            100: 'lightgray'
            101: 'blue'
            102: 'lightblue'
            103: 'lightblue'
            104: 'green'
            105: 'orange'
        srv_id_to_icon =
            25344: family: 'fa', name: 'refresh'     # waste management and recycling
            27718: family: 'maki', name: 'school'
            26016: family: 'maki', name: 'restaurant'
            25658: family: 'maki', name: 'monument'
            26018: family: 'maki', name: 'theatre'
            25646: family: 'maki', name: 'theatre'
            25480: family: 'maki', name: 'library'
            25402: family: 'maki', name: 'toilet'
            25676: family: 'maki', name: 'garden'
            26002: family: 'maki', name: 'lodging'
            25536: family: 'fa', name: 'signal'

        for unit in unit_list
            color = ptype_to_color[unit.provider_type]
            icon = null
            for srv_url in unit.services
                arr = srv_url.split '/'
                id = parseInt arr[arr.length-2], 10
                srv = tree_by_id[id]
                if not srv?
                    continue
                while srv?
                    if srv.id of srv_id_to_icon
                        icon = srv_id_to_icon[srv.id]
                        break
                    srv = srv.parent

            icon = L.AwesomeMarkers.icon
                icon: icon.name if icon? 
                markerColor: color
                prefix: icon.family if icon?
            coords = unit.location.coordinates
            marker = L.marker([coords[1], coords[0]], icon: icon).addTo map

            marker.unit = unit
            marker.on 'click', (ev) ->
                marker = ev.target
                show_unit_details marker.unit

            markers.push marker

    markers = []
    show_division = (div) ->
        json = L.geoJson div.boundary
        map.addLayer json
        map.fitBounds json.getBounds()
        data =
            division: div.ocd_id
            limit: 1000
        $.getJSON SMBACKEND_BASE_URL + 'unit/', data, (data) ->
            draw_units data.objects

    select_division = (div) ->
        params = geometry: true
        $.getJSON SMBACKEND_BASE_URL + "administrative_division/#{div.id}/", params, (data) ->
            show_division data

    $('#search input').on 'typeahead:selected', (ev, item) ->
        if item.division
            select_division item.division
            return

        center = map.getCenter()
        lat = center.lat.toFixed 5
        lon = center.lng.toFixed 5
        ne = map.getBounds().getNorthEast()
        distance = Math.round(ne.distanceTo center)

        url = "http://www.hel.fi/palvelukarttaws/rest/v3/unit/?service=#{item.id}&lat=#{lat}&lon=#{lon}&distance=#{distance}&callback=?"
        $.getJSON url, (data) ->
            for m in markers
                map.removeLayer m
            draw_units data

    window.map = map
    sidebar = L.control.sidebar 'sidebar',
        position: 'left'
    map.addControl sidebar
    map.on 'click', (ev) ->
        sidebar.hide()

    select_division id: 413
