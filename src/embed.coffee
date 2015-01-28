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
    'backbone',
    'backbone.marionette',
    'jquery',
    'iexhr',
    'app/router',
    'app/embedded-views'
],
(
    Models,
    p13n,
    ColorMatcher,
    BaseMapView,
    Backbone,
    Marionette,
    $,
    iexhr,
    Router,
    EmbeddedView
) ->

    app = new Backbone.Marionette.Application()
    window.app = app

    class EmbeddedMapView extends BaseMapView
        get_map_options: ->
            dragging: false
            touchZoom: false
            scrollWheelZoom: false
            doubleClickZoom: false
            boxZoom: false

    app.addInitializer (opts) ->
        #@getRegion('navigation').show navigation
        # The colors are dependent on the currently selected services.
        @color_matcher = new ColorMatcher
        router = new Router
        mapview = new EmbeddedMapView
        app.getRegion('map').show mapview
        embedded_view = new EmbeddedView map_view: mapview
        Backbone.history.start
            pushState: true
            root: app_settings.url_prefix
        @listenTo app.vent, 'all', (ev) ->
            console.log ev

    app.addRegions
        navigation: '#navigation-region'
        map: '#app-container'

    # We wait for p13n/i18next to finish loading before firing up the UI
    $.when(p13n.deferred).done ->
        app.start()
        $app_container = $('#app-container')
        $app_container.attr 'class', p13n.get('map_background_layer')
        $app_container.addClass 'embed'
