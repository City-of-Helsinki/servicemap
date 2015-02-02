define [
    'backbone',
    'backbone.marionette',
    'i18next'
    'app/map',
    'app/widgets',
    'app/jade'
], (
    Backbone,
    Marionette,
    i18n
    map,
    widgets,
    jade
) ->

    # TODO: remove duplicates
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER = [60.171944, 24.941389] # todo: depends on city
    ICON_SIZE = 40
    VIEWPOINTS =
        # meters to show everything within in every direction
        single_unit_immediate_vicinity: 200
    if get_ie_version() and get_ie_version() < 9
        ICON_SIZE *= .8

    _latitude_delta_from_radius = (radius_meters) ->
        (radius_meters / 40075017) * 360
    _longitude_delta_from_radius = (radius_meters, latitude) ->
        _latitude_delta_from_radius(radius_meters) / Math.cos(L.LatLng.DEG_TO_RAD * latitude)

    bounds_from_radius = (radius_meters, lat_lng) ->
        delta = L.latLng _latitude_delta_from_radius(radius_meters),
            _longitude_delta_from_radius(radius_meters, lat_lng.lat)
        min = L.latLng lat_lng.lat - delta.lat, lat_lng.lng - delta.lng
        max = L.latLng lat_lng.lat + delta.lat, lat_lng.lng + delta.lng
        L.latLngBounds [min, max]

    class MapBaseView extends Backbone.Marionette.View
        zoomlevel_single_point: (lat_lng, viewpoint) ->
            bounds = bounds_from_radius VIEWPOINTS[viewpoint], lat_lng
            @map.getBoundsZoom bounds
        initialize: (opts) ->
            @markers = {}
        map_options: {}
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
            @map = map.MapMaker.create_map @$el.get(0), options, @map_options
            @all_markers = @get_feature_group()
            @all_markers.addTo @map
            @post_initialize()
        highlight_unselected_unit: (unit) ->
            # Transiently highlight the unit which is being moused
            # over in search results or otherwise temporarily in focus.
            marker = unit.marker
            popup = marker?.getPopup()
            if popup?.selected
                return
            @clear_popups()
            parent = @all_markers.getVisibleParent unit.marker
            if popup?
                $(marker._popup._wrapper).removeClass 'selected'
                popup.setLatLng marker?.getLatLng()
                @popups.addLayer popup
        clear_popups: (clear_selected) ->
            @popups.eachLayer (layer) =>
                if clear_selected
                    layer.selected = false
                    @popups.removeLayer layer
                else unless layer.selected
                    @popups.removeLayer layer

        highlight_unselected_cluster: (cluster) ->
            # Maximum number of displayed names per cluster.
            COUNT_LIMIT = 3
            @clear_popups()
            child_count = cluster.getChildCount()
            names = _.map cluster.getAllChildMarkers(), (marker) ->
                    p13n.get_translated_attr marker.unit.get('name')
                .sort()
            data = {}
            overflow_count = child_count - COUNT_LIMIT
            if overflow_count > 1
                names = names[0...COUNT_LIMIT]
                data.overflow_message = i18n.t 'general.more_units',
                    count: overflow_count
            data.names = names
            popuphtml = jade.get_template('popup_cluster') data
            popup = @create_popup()
            popup.setLatLng cluster.getBounds().getCenter()
            popup.setContent popuphtml
            @map.on 'zoomstart', =>
                @popups.removeLayer popup
            @popups.addLayer popup

        _add_mouseover_listeners: (markerClusterGroup)->
            markerClusterGroup.on 'clustermouseover', (e) =>
                @highlight_unselected_cluster e.layer
            markerClusterGroup.on 'mouseover', (e) =>
                @highlight_unselected_unit e.layer.unit
            markerClusterGroup.on 'spiderfied', (e) =>
                icon = $(e.target._spiderfied?._icon)
                icon?.fadeTo('fast', 0)
        post_initialize: ->
            @_add_mouseover_listeners @all_markers
            @popups = L.layerGroup()
            @popups.addTo @map
        lat_lng_from_geojson: (object) =>
            object?.get('location')?.coordinates?.slice(0).reverse()
        get_zoomlevel_to_show_all_markers: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                return 8
            else if layer == 'ortographic'
                return 8
            else
                return 14
        create_cluster_icon: (cluster) ->
            count = cluster.getChildCount()
            service_collection = new models.ServiceList()
            markers = cluster.getAllChildMarkers()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                service = new models.Service
                    id: marker.unit.get('root_services')[0]
                    root: marker.unit.get('root_services')[0]
                service_collection.add service

            colors = service_collection.map (service) =>
                app.color_matcher.service_color(service)

            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            new ctor count, ICON_SIZE, colors, service_collection.first().id
        get_feature_group: ->
            L.markerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: (zoom) =>
                    return if (zoom >= @get_zoomlevel_to_show_all_markers()) then 4 else 30
                iconCreateFunction: (cluster) =>
                    @create_cluster_icon(cluster)
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
            if @select_marker?
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
        show_all_units_at_high_zoom: ->
            if $(window).innerWidth() <= app_settings.mobile_ui_breakpoint
                return
            zoom = @map.getZoom()
            if zoom >= @get_zoomlevel_to_show_all_markers()
                if (@selected_units.isSet() and @map.getBounds().contains(@selected_units.first().marker.getLatLng()))
                    # Don't flood a selected unit's surroundings
                    return
                if @selected_services.isSet()
                    return
                if @search_results.isSet()
                    return
                transformed_bounds = map.MapUtils.overlapping_bounding_boxes @map
                bboxes = []
                for bbox in transformed_bounds
                    bboxes.push "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
                app.commands.execute 'addUnitsWithinBoundingBoxes', bboxes
            else
                app.commands.execute 'clearUnits', all: false, bbox: true

    return MapBaseView
