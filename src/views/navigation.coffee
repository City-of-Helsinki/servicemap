define (require) ->
    base                                   = require 'cs!app/views/base'
    EventDetailsView                       = require 'cs!app/views/event-details'
    ServiceTreeView                        = require 'cs!app/views/service-tree'
    PositionDetailsView                    = require 'cs!app/views/position-details'
    UnitDetailsView                        = require 'cs!app/views/unit-details'
    SearchInputView                        = require 'cs!app/views/search-input'
    SidebarRegion                          = require 'cs!app/views/sidebar-region'
    MapView                                = require 'cs!app/map-view'
    {SearchLayoutView, UnitListLayoutView} = require 'cs!app/views/search-results'

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
            @units = options.units
            @selectedEvents = options.selectedEvents
            @selectedPosition = options.selectedPosition
            @searchState = options.searchState
            @routingParameters = options.routingParameters
            @route = options.route
            @breadcrumbs = [] # for service-tree view
            @openViewType = null # initially the sidebar is closed.
            @addListeners()
        addListeners: ->
            @listenTo @searchResults, 'ready', ->
                @change 'search'
            @listenTo @serviceTreeCollection, 'finished', ->
                @openViewType = null
                @change 'browse'
            @listenTo @selectedServices, 'reset', (coll, opts) ->
                unless opts?.skip_navigate
                    @change 'browse'
            @listenTo @selectedPosition, 'change:value', (w, value) ->
                previous = @selectedPosition.previous 'value'
                if previous?
                    @stopListening previous
                if value?
                    @listenTo value, 'change:radiusFilter', @radiusFilterChanged
                if @selectedPosition.isSet()
                    @change 'position'
                else if @openViewType == 'position'
                    @closeContents()
            @listenTo @selectedServices, 'add', (service) ->
                @closeContents()
                @service = service
                @listenTo @service.get('units'), 'finished', =>
                    @change 'service-units'
            @listenTo @selectedServices, 'remove', (service, coll) =>
                if coll.isEmpty()
                    if @openViewType == 'service-units'
                        @closeContents()
                else
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
            @change null
            @openViewType = null
            @header.currentView.updateClasses null
            MapView.setMapActiveAreaMaxHeight maximize: true

        radiusFilterChanged: (value) ->
            if value.get('radiusFilter') > 0
                @listenToOnce @units, 'finished', =>
                    @change 'radius'

        change: (type, opts) ->

            # Don't react if browse is already opened
            return if type is 'browse' and @openViewType is 'browse'

            switch type
                when 'browse'
                    view = new ServiceTreeView
                        collection: @serviceTreeCollection
                        selectedServices: @selectedServices
                        breadcrumbs: @breadcrumbs
                when 'radius'
                    view = new UnitListLayoutView
                        fullCollection: @units
                        collectionType: 'radius'
                        position: @selectedPosition.value()
                        resultType: 'unit'
                        onlyResultType: true
                when 'search'
                    view = new SearchLayoutView
                        collection: @searchResults
                    if opts?.disableAutoFocus
                        view.disableAutoFocus()
                when 'service-units'
                    view = new UnitListLayoutView
                        fullCollection: @units
                        collectionType: 'service'
                        resultType: 'unit'
                        onlyResultType: true
                        selectedServices: @selectedServices
                when 'details'
                    view = new UnitDetailsView
                        model: @selectedUnits.first()
                        route: @route
                        parent: @
                        routingParameters: @routingParameters
                        searchResults: @searchResults
                        selectedUnits: @selectedUnits
                        selectedPosition: @selectedPosition
                when 'event'
                    view = new EventDetailsView
                        model: @selectedEvents.first()
                when 'position'
                    view = new PositionDetailsView
                        model: @selectedPosition.value()
                        route: @route
                        selectedPosition: @selectedPosition
                        routingParameters: @routingParameters
                else
                    @opened = false
                    view = null
                    @contents.reset()

            @updatePersonalisationButtonClass type

            if view?
                @contents.show view, animationType: @getAnimationType(type)
                @openViewType = type
                @opened = true
                @listenToOnce view, 'user:close', (ev) =>
                    if type == 'details'
                        if not @selectedServices.isEmpty()
                            @change 'service-units'
                        else if 'distance' of @units.filters
                            @change 'radius'
            unless type == 'details'
                # TODO: create unique titles for routes that require it
                app.vent.trigger 'site-title:change', null

        updatePersonalisationButtonClass: (type) ->
            # Update personalisation icon visibility.
            # Notice: "hidden" class only affects narrow media.
            if type in ['browse', 'search', 'details', 'event', 'position']
                $('#personalisation').addClass 'hidden'
            else
                $('#personalisation').removeClass 'hidden'

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
            'keypress .header': 'toggleOnKeypress'
            'click .action-button.close-button': 'close'

        initialize: (options) ->
            @navigationLayout = options.layout
            @searchState = options.searchState
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits

        onShow: ->
            searchInputView = new SearchInputView(@searchState, @searchResults, _.bind(@_expandSearch, @))
            @search.show searchInputView
            @listenTo searchInputView, 'open', =>
                @updateClasses 'search'
                @navigationLayout.updatePersonalisationButtonClass 'search'
            @browse.show new BrowseButtonView()

        _expandSearch: ->
            @_open 'search', disableAutoFocus: true

        _open: (actionType, opts) ->
            @updateClasses actionType
            @navigationLayout.change actionType, opts

        open: (event) ->
            @_open $(event.currentTarget).data('type')

        toggleOnKeypress: (event) ->
            target = $(event.currentTarget).data('type')
            isNavigationVisible = !!$('#navigation-contents').children().length

            # An early return if the key is not 'enter'
            return if event.keyCode isnt 13
            # An early return if the element is search input
            return if target == 'search'

            if isNavigationVisible
                @_close target
            else
                @_open target

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
