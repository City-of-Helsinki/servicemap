define [
    'underscore',
    'backbone',
    'leaflet',
    'i18next',
    'moment',
    'bootstrap-datetimepicker',
    'typeahead.bundle',
    'raven',
    'app/views/base',
    'app/p13n',
    'app/widgets',
    'app/jade',
    'app/models',
    'app/search',
    'app/color',
    'app/draw',
    'app/transit',
    'app/animations',
    'app/accessibility',
    'app/accessibility_sentences',
    'app/sidebar-region',
    'app/spinner',
    'app/dateformat',
    'app/map-view'
], (
    _,
    Backbone,
    Leaflet,
    i18n,
    moment,
    datetimepicker,
    typeahead,
    Raven,
    base,
    p13n,
    widgets,
    jade,
    models,
    search,
    colors,
    draw,
    transit,
    animations,
    accessibility,
    accessibility_sentences,
    SidebarRegion,
    SMSpinner,
    dateformat,
    MapView
) ->

    PAGE_SIZE = 200
    # Mobile UI is used below this screen width.
    MOBILE_UI_BREAKPOINT = app_settings.mobile_ui_breakpoint

    set_site_title = (route_title) ->
        # Sets the page title. Should be called when the view that is
        # considered the main view changes.
        title = "#{i18n.t('general.site_title')}"
        if route_title
            title = "#{p13n.get_translated_attr(route_title)} | " + title
        $('head title').text title

    exports =
        LandingTitleView: LandingTitleView
        TitleView: TitleView
        ServiceTreeView: ServiceTreeView
        ServiceCart: ServiceCart
        LanguageSelectorView: LanguageSelectorView
        NavigationLayout: NavigationLayout
        PersonalisationView: PersonalisationView

    return exports
