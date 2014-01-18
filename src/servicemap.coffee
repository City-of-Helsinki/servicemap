requirejs.config
    baseUrl: 'vendor'
    paths:
        app: '../js'

SMBACKEND_BASE_URL = "http://localhost:8000/v1/"

requirejs ['app/map', 'lunr', 'servicetree', 'typeahead.bundle'], (map) ->
    SearchControl = L.Control.extend
        options: {
            position: 'topleft'
        },

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

    markers = []
    show_division = (div) ->
        json = L.geoJson div.boundary
        map.addLayer json
        map.fitBounds json.getBounds()

    $("#search input").on 'typeahead:selected', (ev, item) ->
        if item.division
            div = item.division
            params = geometry: true
            $.getJSON SMBACKEND_BASE_URL + "administrative_division/#{div.id}/", params, (data) ->
                show_division data
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
            for unit in data
                icon = L.AwesomeMarkers.icon
                    icon: 'coffee'
                    markerColor: 'red'
                marker = L.marker([unit.latitude, unit.longitude], icon: icon).addTo map
                popup_html = "<strong>#{unit.name}</strong><div>#{unit.street_address_fi}</div>"
                marker.bindPopup popup_html
                markers.push marker
    window.map = map
