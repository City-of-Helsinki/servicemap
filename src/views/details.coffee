define [
    'cs!app/map-view',
    'cs!app/views/base',
    'cs!app/views/route',
    'cs!app/base'
], (
    MapView,
    base,
    RouteView,
    {getIeVersion: getIeVersion}
) ->

    class DetailsView extends base.SMLayout
        id: 'details-view-container'
        className: 'navigation-element'
        regions:
            'routeRegion': '.section.route-section'
        events:
            'click .collapse-button': 'toggleCollapse'
            'click .map-active-area': 'showMap'
            'click .mobile-header': 'showContent'
            'show.bs.collapse': 'scrollToExpandedSection'
            'hide.bs.collapse': '_removeLocationHash'

        initialize: (options) ->
            @selectedPosition = options.selectedPosition
            @routingParameters = options.routingParameters
            @route = options.route
            
        onRender: ->
            @listenTo app.vent, 'hashpanel:render', (hash) -> @_triggerPanel(hash)
            @routeRegion.show new RouteView
                model: @model
                route: @route
                parentView: @
                routingParameters: @routingParameters
                selectedUnits: @selectedUnits || null
                selectedPosition: @selectedPosition

        showMap: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: true

        showContent: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: false

        scrollToExpandedSection: (event) ->
            $container = @$el.find('.content').first()
            $target = $(event.target)
            @_setLocationHash($target)

            # Don't scroll if route leg is expanded.
            return if $target.hasClass('steps')
            $section = $target.closest('.section')
            scrollTo = $container.scrollTop() + $section.position().top
            $('#details-view-container .content').animate(scrollTop: scrollTo)

        _removeLocationHash: (event) ->
            window.location.hash = '' unless @_checkIEversion()

        _setLocationHash: (target) ->
            window.location.hash = '!' + target.attr('id') unless @_checkIEversion()

        _checkIEversion: () ->
            getIeVersion() and getIeVersion() < 10

        _triggerPanel: (hash) ->
            _.defer =>
                triggerElem = $("a[href='" + hash + "']")
                triggerElem.trigger('click').attr('tabindex', -1).focus()


    DetailsView

