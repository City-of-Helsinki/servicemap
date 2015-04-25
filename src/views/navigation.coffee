define [
    'app/views/base',
    'app/views/event-details',
    'app/views/service-tree',
    'app/views/position-details',
    'app/views/unit-details',
    'app/views/search-input',
    'app/views/search-results',
    'app/views/sidebar-region',
    'app/map-view'
], (
    base,
    EventDetailsView,
    ServiceTreeView,
    PositionDetailsView,
    UnitDetailsView,
    SearchInputView,
    {SearchLayoutView: SearchLayoutView,
    ServiceUnitsLayoutView: ServiceUnitsLayoutView},
    SidebarRegion,
    MapView
) ->

    class NavigationLayout extends base.SMLayout
        className: 'service-sidebar'
        template: 'navigation-layout'
        regionType: SidebarRegion
        regions:
            header: '#navigation-header'
            contents: '#navigation-contents'
        onShow: ->
            @header.show new NavigationHeaderView
                layout: this
                searchState: @searchState
                searchResults: @searchResults
                selectedUnits: @selectedUnits
        initialize: (options) ->
            @serviceTreeCollection = options.serviceTreeCollection
            @selectedServices = options.selectedServices
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits
            @selectedEvents = options.selectedEvents
            @selectedPosition = options.selectedPosition
            @searchState = options.searchState
            @routingParameters = options.routingParameters
            @route = options.route
            @userClickCoordinatePosition = options.userClickCoordinatePosition
            @breadcrumbs = [] # for service-tree view
            @openViewType = null # initially the sidebar is closed.
            @addListeners()
        addListeners: ->
            @listenTo @searchResults, 'reset', ->
                unless @searchResults.isEmpty()
                    @change 'search'
            @listenTo @searchResults, 'ready', ->
                unless @searchResults.isEmpty()
                    @change 'search'
            @listenTo @serviceTreeCollection, 'finished', ->
                @openViewType = null
                @change 'browse'
            @listenTo @selectedServices, 'reset', ->
                @change 'browse'
            @listenTo @selectedPosition, 'change:value', ->
                if @selectedPosition.isSet()
                    @change 'position'
                else if @openViewType = 'position'
                    @closeContents()
            @listenTo @selectedServices, 'add', (service) ->
                @closeContents()
                @service = service
                @listenTo @service.get('units'), 'finished', =>
                    @change 'service-units'
            @listenTo @selectedUnits, 'reset', (unit, coll, opts) ->
                currentViewType = @contents.currentView?.type
                if currentViewType == 'details'
                    if @searchResults.isEmpty() and @selectedUnits.isEmpty()
                        @closeContents()
                unless @selectedUnits.isEmpty()
                    @change 'details'
            @listenTo @selectedUnits, 'remove', (unit, coll, opts) ->
                @change null
            @listenTo @selectedEvents, 'reset', (unit, coll, opts) ->
                unless @selectedEvents.isEmpty()
                    @change 'event'
            @contents.on('show', @updateMaxHeights)
            $(window).resize @updateMaxHeights
            @listenTo(app.vent, 'landing-page-cleared', @setMaxHeight)
        updateMaxHeights: =>
            @setMaxHeight()
            currentViewType = @contents.currentView?.type
            MapView.setMapActiveAreaMaxHeight
                maximize: not currentViewType or currentViewType == 'search'
        setMaxHeight: =>
            # Set the sidebar content max height for proper scrolling.
            $limitedElement = @$el.find('.limit-max-height')
            return unless $limitedElement.length
            maxHeight = $(window).innerHeight() - $limitedElement.offset().top
            $limitedElement.css 'max-height': maxHeight
            @$el.find('.map-active-area').css 'padding-bottom', MapView.mapActiveAreaMaxHeight()
        getAnimationType: (newViewType) ->
            currentViewType = @contents.currentView?.type
            if currentViewType
                switch currentViewType
                    when 'event'
                        return 'right'
                    when 'details'
                        switch newViewType
                            when 'event' then return 'left'
                            when 'details' then return 'up-and-down'
                            else return 'right'
                    when 'service-tree'
                        return @contents.currentView.animationType or 'left'
            return null

        closeContents: ->
            @openViewType = null
            @change null
            @header.currentView.updateClasses null
            MapView.setMapActiveAreaMaxHeight maximize: true

        change: (type) ->
            if type == @openViewType
                return
            if type is null
                type = @openViewType

            # Only render service tree if browse is open in the sidebar.
            # if type == 'browse' and @openViewType != 'browse'
            #     return
            switch type
                when 'browse'
                    view = new ServiceTreeView
                        collection: @serviceTreeCollection
                        selectedServices: @selectedServices
                        breadcrumbs: @breadcrumbs
                when 'search'
                    view = new SearchLayoutView
                        collection: @searchResults
                when 'service-units'
                    view = new ServiceUnitsLayoutView
                        fullCollection: @service.get('units')
                        resultType: 'unit'
                        onlyResultType: true
                when 'details'
                    view = new UnitDetailsView
                        model: @selectedUnits.first()
                        route: @route
                        parent: @
                        routingParameters: @routingParameters
                        searchResults: @searchResults
                        selectedUnits: @selectedUnits
                        selectedPosition: @selectedPosition
                        userClickCoordinatePosition: @userClickCoordinatePosition
                when 'event'
                    view = new EventDetailsView
                        model: @selectedEvents.first()
                when 'position'
                    view = new PositionDetailsView
                        model: @selectedPosition.value()
                        route: @route
                        selectedPosition: @selectedPosition
                        routingParameters: @routingParameters
                        userClickCoordinatePosition: @userClickCoordinatePosition
                else
                    @opened = false
                    view = null
                    @contents.close()

            # Update personalisation icon visibility.
            if type in ['browse', 'search', 'details', 'event', 'position']
                $('#personalisation').addClass('hidden')
            else
                $('#personalisation').removeClass('hidden')

            if view?
                @contents.show view, animationType: @getAnimationType(type)
                @openViewType = type
                @opened = true
            unless type == 'details'
                # TODO: create unique titles for routes that require it
                app.vent.trigger 'site-title:change', null

    class NavigationHeaderView extends base.SMLayout
        # This view is responsible for rendering the navigation
        # header which allows the user to switch between searching
        # and browsing.
        className: 'container'
        template: 'navigation-header'
        regions:
            search: '#search-region'
            browse: '#browse-region'
        events:
            'click .header': 'open'
            'click .action-button.close-button': 'close'
        initialize: (options) ->
            @navigationLayout = options.layout
            @searchState = options.searchState
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits
            @listenTo @searchState, 'change:input_query', (model, value, opts) =>
                if opts.initial
                    @_open 'search'
                else unless value or opts.clearing or opts.keepOpen
                    @_close 'search'
        onShow: ->
            @search.show new SearchInputView(@searchState, @searchResults)
            @browse.show new BrowseButtonView()
        _open: (actionType) ->
            @updateClasses actionType
            @navigationLayout.change actionType
        open: (event) ->
            @_open $(event.currentTarget).data('type')
        _close: (headerType) ->
            @updateClasses null

            # Clear search query if search is closed.
            if headerType is 'search'
                @$el.find('input').val('')
                app.commands.execute 'closeSearch'
            if headerType is 'search' and not @selectedUnits.isEmpty()
                # Don't switch out of unit details when closing search.
                return
            @navigationLayout.closeContents()
        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            unless $(event.currentTarget).hasClass('close-button')
                return false
            headerType = $(event.target).closest('.header').data('type')
            @_close headerType
        updateClasses: (opening) ->
            classname = "#{opening}-open"
            if @$el.hasClass classname
                return
            @$el.removeClass().addClass('container')
            if opening?
                @$el.addClass classname

    class BrowseButtonView extends base.SMItemView
        template: 'navigation-browse'


    NavigationLayout
