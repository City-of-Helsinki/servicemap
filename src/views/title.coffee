define (require) ->
    p13n = require 'cs!app/p13n'
    jade = require 'cs!app/jade'
    base = require 'cs!app/views/base'

    class TitleView extends base.SMItemView
        template: 'title-view'
        className: 'title-control'
        initialize: ->
            @listenTo p13n, 'change', (path) ->
                @render() if path[0] is 'map_background_layer'
        serializeData: ->
            map_background: p13n.get('map_background_layer')
            lang: p13n.getLanguage()
            root: appSettings.url_prefix

    class LandingTitleView extends base.SMItemView
        template: 'landing-title-view'
        id: 'title'
        className: 'landing-title-control'
        initialize: ->
            @listenTo(app.vent, 'title-view:hide', @hideTitleView)
            @listenTo(app.vent, 'title-view:show', @unHideTitleView)
        serializeData: ->
            isHidden: @isHidden
            lang: p13n.getLanguage()
        hideTitleView: ->
            $('body').removeClass 'landing'
            @isHidden = true
            @render()
        unHideTitleView: ->
            $('body').addClass 'landing'
            @isHidden = false
            @render()

    TitleView: TitleView
    LandingTitleView: LandingTitleView
