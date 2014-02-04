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

SMBACKEND_BASE_URL = sm_settings.backend_url + '/'

LANGUAGE = 'fi'

SRV_TEXT =
    fi: 'Palvelut'
    en: 'Services'

requirejs ['app/map', 'app/models', 'jquery', 'lunr', 'servicetree', 'typeahead', 'L.Control.Sidebar'], (map_stuff, Models, $) ->
    map = map_stuff.map

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

    new SearchControl().addTo map

    map_stuff.layer_control.addTo map

    index = lunr ->
        @field "name_#{LANGUAGE}"
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

    key_name = "servicemap_lun_index_#{LANGUAGE}"
    index_str = localStorage.getItem key_name
    if index_str
        index_json = JSON.parse index_str
        index = lunr.Index.load index_json
        process_tree SERVICE_TREE, null, false
    else
        process_tree SERVICE_TREE, null, true
        localStorage.setItem key_name, JSON.stringify index.toJSON()

    sections = [
        {
            name: 'services'
            source: (query, process) ->
                res_list = index.search query
                output = []
                for res in res_list[0..20]
                    service = tree_by_id[parseInt(res.ref, 10)]
                    attr_name = "name_#{LANGUAGE}"
                    output.push id: service.id, value: service[attr_name], service: service
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
        console.log "show details"
        console.log unit
        html = "<h3>#{unit.name[LANGUAGE]}</h3>"

        if unit.department
            dept = dept_list.get unit.department
            html += "<div class='department'>#{dept.get('name')[LANGUAGE]}</div><hr/>"

        if unit.picture_url
            html += "<img src=\"#{unit.picture_url}\" width=400>"

        if unit.description? and unit.description[LANGUAGE]
            html += "<p>#{unit.description[LANGUAGE]}</p><hr/>"

        contact_html = ''
        if unit.street_address? and unit.street_address[LANGUAGE]
            contact_html += unit.street_address[LANGUAGE] + '<br/>'
        if unit.phone
            contact_html += 'p. ' + unit.phone
        if contact_html
            html += "<div class='contact'>#{contact_html}</div><hr/>"

        html += "<h4>#{SRV_TEXT[LANGUAGE]}</h4>"
        srv_html = "<ul>"
        for srv_url in unit.services
            arr = srv_url.split '/'
            id = parseInt arr[arr.length-2], 10
            srv = tree_by_id[id]
            if not srv?
                continue
            srv_attr = "name_#{LANGUAGE}"
            srv_html += "<li>#{srv[srv_attr]} (#{id})</li>"
        srv_html += "</ul>"
        html += srv_html
        $("#sidebar").html html
        sidebar._active_marker = unit.marker
        center = unit.marker.getLatLng()
        if sidebar.isVisible()
            delta_x = -sidebar.getOffset() / 2
            point = map.latLngToLayerPoint center
            point.x += delta_x
            new_center = map.layerPointToLatLng point
            map.panTo new_center, duration: 0.5
        else
            sidebar.show center

    markers = []
    division_layer = null

    clear_markers = ->
        for m in markers
            map.removeLayer m
        markers = []

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

        clear_markers()
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
            popup = L.popup(closeButton: false).setContent "<strong>#{unit.name.fi}</strong>"
            marker = L.marker([coords[1], coords[0]], icon: icon)
                .bindPopup(popup)
                .addTo(map)

            marker.unit = unit
            unit.marker = marker
            marker.on 'click', (ev) ->
                marker = ev.target
                show_unit_details marker.unit

            markers.push marker

    show_division = (div) ->
        if division_layer
            map.removeLayer division_layer
        division_layer = L.geoJson div.boundary,
            style: (feature) ->
                fillOpacity: 0
                lineJoin: 'round'
                weight: 10
                color: 'rgb(53, 69, 96)'
                opacity: 0.5

        map.addLayer division_layer
        map.fitBounds division_layer.getBounds()
        data =
            division: div.ocd_id
            limit: 1000
        $.getJSON SMBACKEND_BASE_URL + 'unit/', data, (data) ->
            draw_units data.objects

    select_division = (div) ->
        params = geometry: true
        $.getJSON SMBACKEND_BASE_URL + "administrative_division/#{div.id}/", params, (data) ->
            show_division data

    select_category = (srv_id) ->
        #center = map.getCenter()
        #lat = center.lat.toFixed 5
        #lon = center.lng.toFixed 5
        #bounds = map.getBounds()
        #distance = Math.round(ne.distanceTo center)

        params =
            services: srv_id
            limit: 1000
        $.getJSON SMBACKEND_BASE_URL + "unit/", params, (data) ->
            clear_markers()
            if division_layer
                map.removeLayer division_layer
            draw_units data.objects

    $('#search input').on 'typeahead:selected', (ev, item) ->
        if item.division
            select_division item.division
            return

        select_category item.id

    window.map = map
    sidebar = L.control.sidebar 'sidebar',
        position: 'left'
    map.addControl sidebar
    sidebar.on 'hide', ->
        sidebar._active_marker.closePopup()

    map.on 'click', (ev) ->
        sidebar.hide()

    #select_division id: 413
