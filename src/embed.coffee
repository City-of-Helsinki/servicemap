requirejs_config =
    baseUrl: app_settings.static_path + 'vendor'
    paths:
        app: '../js'
    shim:
        bootstrap:
            deps: ['jquery']
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        'iexhr':
            deps: ['jquery']

requirejs.config requirejs_config

PAGE_SIZE = 1000

# TODO: move to common file??
window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"

    if not is_internet_explorer()
        return false

    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

if app_settings.sentry_url
    config = {}
    if app_settings.sentry_disable
        config.shouldSendCallback = -> false
    requirejs ['raven'], (Raven) ->
        Raven.config(app_settings.sentry_url, config).install()
        Raven.setExtraContext git_commit: app_settings.git_commit_id

requirejs [
    'app/models',
    'app/p13n',
    'app/color',
    'app/map-base-view'
    'app/map',
    'backbone',
    'backbone.marionette',
    'jquery',
    'iexhr',
    'bootstrap',
    'app/router',
    'app/embedded-views'
],
(
    models,
    p13n,
    ColorMatcher,
    BaseMapView,
    map,
    Backbone,
    Marionette,
    $,
    iexhr,
    Bootstrap,
    Router,
    TitleBarView
) ->

    app = new Backbone.Marionette.Application()
    window.app = app

    class EmbeddedMapView extends BaseMapView
        map_options:
            dragging: false
            touchZoom: false
            scrollWheelZoom: false
            doubleClickZoom: false
            boxZoom: false
        draw_units: (units, opts) ->
            units_with_location = units.filter (unit) => unit.get('location')?
            markers = units_with_location.map (unit) => @create_marker(unit)
            _.each markers, (marker) => @all_markers.addLayer marker
            if opts.zoom? and opts.zoom
                if units.length == 1
                    level = @zoomlevel_single_point markers[0].getLatLng(),
                        'single_unit_immediate_vicinity'
                    @map.setView markers[0].getLatLng(), level, animate: false
                else
                    @map.fitBounds L.latLngBounds(_.map(markers, (m) => m.getLatLng()))
        fit_bbox: (bbox) =>
            sw = L.latLng(bbox.slice(0,2))
            ne = L.latLng(bbox.slice(2,4))
            bounds = L.latLngBounds(sw, ne)
            @map.fitBounds bounds
            @show_all_units_at_high_zoom()

        show_all_units_at_high_zoom: ->
            transformed_bounds = map.MapUtils.overlapping_bounding_boxes @map
            bboxes = []
            for bbox in transformed_bounds
                bboxes.push "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"
            app.commands.execute 'addUnitsWithinBoundingBoxes', bboxes

    app_state =
        # TODO handle pagination
        divisions: new models.AdministrativeDivisionList
        units: new models.UnitList pageSize: 3000

    class EmbedControl
        constructor: (@state) ->
            _.extend @, Backbone.Events
        add_units_within_bounding_boxes: (bbox_strings) =>
            @state.units.clearFilters()
            get_bbox = (bbox_strings) =>
                # Fetch bboxes sequentially
                if bbox_strings.length == 0
                    @state.units.setFilter 'bbox', true
                    @state.units.trigger 'finished'
                    return
                bbox_string = _.first bbox_strings
                unit_list = new models.UnitList()
                opts = success: (coll, resp, options) =>
                    if unit_list.length
                        @state.units.add unit_list.toArray()
                    unless unit_list.fetchNext(opts)
                        unit_list.trigger 'finished'
                unit_list.pageSize = PAGE_SIZE
                unit_list.setFilter 'bbox', bbox_string
                layer = p13n.get 'map_background_layer'
                unit_list.setFilter 'bbox_srid', if layer == 'servicemap' then 3067 else 3879
                unit_list.setFilter 'only', 'name,location,root_services'
                # Default exclude filter: statues, wlan hot spots
                unit_list.setFilter 'exclude_services', '25658,25538'
                @listenTo unit_list, 'finished', =>
                    get_bbox _.rest(bbox_strings)
                unit_list.fetch(opts)
            @state.units.reset [], retain_markers: true
            get_bbox(bbox_strings)

    app.addInitializer (opts) ->
        # The colors are dependent on the currently selected services.
        @color_matcher = new ColorMatcher
        mapview = new EmbeddedMapView
        app.getRegion('map').show mapview
        router = new Router app, app_state, mapview
        Backbone.history.start
            pushState: true
            root: app_settings.url_prefix
        control = new EmbedControl app_state
        @commands.setHandler 'addUnitsWithinBoundingBoxes', (bboxes) => control.add_units_within_bounding_boxes(bboxes)

    app.addRegions
        navigation: '#navigation-region'
        map: '#app-container'

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        $app_container = $('#app-container')
        $app_container.attr 'class', p13n.get('map_background_layer')
        $app_container.addClass 'embed'
