define [
    'backbone',
    'backbone.marionette',
    'app/map',
    'app/widgets'
], (
    Backbone,
    Marionette,
    map,
    widgets
) ->

    # TODO: remove duplicates
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city
    ICON_SIZE = 40
    if get_ie_version() and get_ie_version() < 9
        ICON_SIZE *= .8

    class MapBaseView extends Backbone.Marionette.View
        initialize: (opts) ->
            @markers = {}
        render: ->
            @$el.attr 'id', 'map'
        get_map: ->
            @map
        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            map_style =
                if p13n.get_accessibility_mode 'color_blind'
                    'accessible_map'
                else
                    p13n.get 'map_background_layer'
            options =
                style: map_style
                language: p13n.get_language()
            @map = map.MapMaker.create_map @$el.get(0), options, @get_map_options()
            @all_markers = @get_feature_group()
            @all_markers.addTo @map
            @post_initialize()
        get_map_options: ->
            {}
        post_initialize: ->
            @map.setView DEFAULT_CENTER, 10
        lat_lng_from_geojson: (object) =>
            object?.get('location')?.coordinates?.slice(0).reverse()
        get_feature_group: ->
            L.featureGroup()
        draw_units: (units) ->
            @all_markers.clearLayers()
            @markers = {}
            units_with_location = units.filter (unit) => unit.get('location')?
            markers = units_with_location.map (unit) => @create_marker(unit)
            _.each markers, (marker) =>
                @all_markers.addLayer marker
        create_marker: (unit) ->
            id = unit.get 'id'
            if id of @markers
                return @markers[id]
            html_content = "<div class='unit-name'>#{unit.get_text 'name'}</div>"
            popup = @create_popup().setContent html_content
            icon = @create_icon unit, @selected_services
            marker = L.marker @lat_lng_from_geojson(unit),
                icon: icon
                zIndexOffset: 100
            marker.unit = unit
            unit.marker = marker
            @listenTo marker, 'click', @select_marker

            marker.bindPopup(popup)
            @markers[id] = marker
        create_popup: (offset) ->
            opts =
                closeButton: false
                autoPan: false
                zoomAnimation: false
                minWidth: 500
                className: 'unit'
            if offset? then opts.offset = offset
            new widgets.LeftAlignedPopup opts
        create_icon: (unit, services) ->
            color = app.color_matcher.unit_color(unit) or 'rgb(255, 255, 255)'
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasIcon
            else
                ctor = widgets.PlantCanvasIcon
            new ctor ICON_SIZE, color, unit.id

    return MapBaseView
