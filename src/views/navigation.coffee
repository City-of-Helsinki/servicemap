define (require) ->
    base                                   = require 'cs!app/views/base'
    models                                 = require 'cs!app/models'
    EventDetailsView                       = require 'cs!app/views/event-details'
    ServiceTreeView                        = require 'cs!app/views/service-tree'
    PositionDetailsView                    = require 'cs!app/views/position-details'
    UnitDetailsView                        = require 'cs!app/views/unit-details'
    SearchInputView                        = require 'cs!app/views/search-input'
    SidebarRegion                          = require 'cs!app/views/sidebar-region'
    MapView                                = require 'cs!app/map-view'
    {SidebarLoadingIndicatorView}          = require 'cs!app/views/loading-indicator'
    {SearchLayoutView, UnitListLayoutView} = require 'cs!app/views/search-results'
    {InformationalMessageView}             = require 'cs!app/views/message'
    {SearchResultsSummaryLayout, UnitListingView} = require 'cs!app/views/new-search-results.coffee'

    class NavigationLayout extends base.SMLayout
        className: 'service-sidebar'
        template: 'navigation-layout'
        regionClass: SidebarRegion
        regions:
            header: '#navigation-header'
            contents: '#navigation-contents'
        onShow: ->
            @navigationHeaderView = new NavigationHeaderView
                layout: this
                searchState: @searchState
                searchResults: @searchResults
                selectedUnits: @selectedUnits
            @header.show @navigationHeaderView
        initialize: (@appModels) ->
            {
                @selectedServices
                @serviceNodes
                @selectedServiceNodes
                @searchResults
                @selectedUnits
                @units
                @selectedEvents
                @selectedPosition
                @searchState
                @routingParameters
                @route
                @cancelToken
                @informationalMessage
            } = @appModels
            @breadcrumbs = [] # for service-tree view
            @openViewType = null # initially the sidebar is closed.
            @addListeners()
            @restoreViewTypeOnCancel = null
            @changePending = false

        addListeners: ->
            @listenTo @cancelToken, 'change:value', =>
                wrappedValue = @cancelToken.value()
                activeHandler = (token, opts) =>
                    return unless token.get 'active'
                    @stopListening token, 'change:active'
                    return if token.local
                    @change 'loading-indicator'
                @listenTo wrappedValue, 'change:active', activeHandler
                @listenTo wrappedValue, 'complete', =>
                    if @contents.currentView.isLoadingIndicator
                        @contents.empty()
                wrappedValue.trigger 'change:active', wrappedValue, {}
                wrappedValue.addHandler =>
                    @stopListening wrappedValue
                    if @restoreViewTypeOnCancel
                        @change @restoreViewTypeOnCancel unless wrappedValue.local
                    else if @appModels.isEmpty()
                        @change null
            @listenTo @searchResults, 'ready', ->
                @change 'search'
            @listenTo @serviceNodes, 'finished', ->
                @openViewType = null
                @change 'browse'

            [@selectedServices, @selectedServiceNodes].forEach (serviceItemCollection) =>
                @listenTo serviceItemCollection, 'reset', (coll, opts) ->
                    if opts?.stateRestored
                        if serviceItemCollection.size() > 0
                            @change 'service-node-units'
                        return
                    @change 'browse' unless opts?.skip_navigate

                @listenTo serviceItemCollection, 'add', (serviceItem) ->
                    @navigationHeaderView.updateClasses null
                    @listenTo serviceItem.get('units'), 'finished', =>
                        @change 'service-node-units'

                @listenTo serviceItemCollection, 'has-service-item', ->
                    @navigationHeaderView.updateClasses null
                    @change 'service-node-units'

                @listenTo serviceItemCollection, 'remove', (serviceItem, coll) =>
                    if coll.isEmpty()
                        if @openViewType == 'service-node-units'
                            @closeContents()
                    else
                        @listenToOnce @units, 'batch-remove', =>
                            @change 'service-node-units'

            @listenTo @selectedPosition, 'change:value', (w, value) ->
                previous = @selectedPosition.previous 'value'
                if previous?
                    @stopListening previous
                if value?
                    @listenTo value, 'change:radiusFilter', @radiusFilterChanged
                if @selectedPosition.isSet()
                    return unless value?.get 'selected'
                    @change 'position'
                else if @openViewType == 'position'
                    @closeContents()
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
            @listenTo @informationalMessage, 'change:messageKey', (message) ->
                @change 'message'
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
            if @changePending
                 @listenToOnce @contents, 'show', =>
                     @changePending = false
                     @change type, opts
                 return
            # Don't react if browse is already opened
            return if type is 'browse' and @openViewType is 'browse'

            if type == 'browse'
                @restoreViewTypeOnCancel = type
            else if @openViewType == @restoreViewTypeOnCancel and type not in [@openViewType, null, 'loading-indicator']
                @restoreViewTypeOnCancel = null

            switch type
                when 'browse'
                    view = new ServiceTreeView
                        collection: @serviceNodes
                        selectedServiceNodes: @selectedServiceNodes
                        breadcrumbs: @breadcrumbs
                when 'radius'
                    view = new UnitListingView
                        model: new Backbone.Model
                            collectionType: 'radius'
                            resultType: 'unit'
                            onlyResultType: true
                            position: @selectedPosition.value()
                            count: @units.length
                        fullCollection: @units
                        collection: new models.UnitList()

                when 'search'
                    if @searchResults.length > 0
                        # We want to prevent any open UI element from
                        # closing just because the user clicked on the
                        # search bar.
                        view = new SearchResultsSummaryLayout
                            collection: @searchResults
                        if opts?.disableAutoFocus
                            view.disableAutoFocus()
                when 'service-node-units'
                    view = new UnitListingView
                        model: new Backbone.Model
                            collectionType: 'service'
                            resultType: 'unit'
                            onlyResultType: true
                            count: @units.length
                        selectedServiceNodes: @selectedServiceNodes
                        collection: new models.UnitList()
                        fullCollection: @units
                    @listenTo view, 'close', =>
                        @change 'browse'
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
                when 'message'
                    view = new InformationalMessageView
                        model: @informationalMessage
                when 'loading-indicator'
                    view = new SidebarLoadingIndicatorView
                        model: @cancelToken.value()
                else
                    @opened = false
                    view = null
                    @contents.empty()

            @updatePersonalisationButtonClass type

            if view?
               if @changePending
                    @listenToOnce @contents, 'show', =>
                        @changePending = false
                        @change type, opts
                    return
                showView = =>
                    @changePending = true
                    @listenToOnce @contents, 'show', => @changePending = false
                    @contents.show view, animationType: @getAnimationType(type)
                    @openViewType = type
                    @opened = true
                    @listenToOnce view, 'user:close', (ev) =>
                        if type == 'details'
                            if not @selectedServiceNodes.isEmpty()
                                @change 'service-node-units'
                            else if 'distance' of @units.filters
                                @change 'radius'
                if view.isReady()
                    showView()
                else
                    @listenToOnce view, 'ready', -> showView()
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

        events: ->
            'click .header.search': 'open'
            'keypress .header': @keyboardHandler @toggleOpen, ['enter']
            'click .header.browse': 'toggleOpen'
            'click .action-button.close-button': 'close'

        initialize: (options) ->
            @navigationLayout = options.layout
            @searchState = options.searchState
            @searchResults = options.searchResults
            @selectedUnits = options.selectedUnits

        onShow: ->
            searchInputView = new SearchInputView({@searchState, @searchResults})
            @search.show searchInputView
            @listenTo searchInputView, 'open', =>
                @updateClasses 'search'
                @navigationLayout.updatePersonalisationButtonClass 'search'
            @browse.show new BrowseButtonView()

        _open: (actionType, opts) ->
            @updateClasses actionType
            @navigationLayout.change actionType, opts

            # Toggle aria-pressed on browse button
            if actionType is 'browse'
                $('#browse-region').attr('aria-pressed', true);

        open: (event) ->
            @_open $(event.currentTarget).data('type')

        toggleOpen: (event) ->
            target = $(event.currentTarget).data('type')
            isNavigationVisible = !!$('#navigation-contents').children().length

            # An early return if the element is search input
            return if target == 'search'

            if isNavigationVisible
                @_close target
            else
                @_open target

        _close: (headerType) ->
            @updateClasses null

            # Toggle aria-pressed on browse button
            if headerType is 'browse'
                $('#browse-region').attr('aria-pressed', false);

            # Clear search query if search is closed.
            if headerType is 'search'
                @$el.find('input').val('')
                app.request 'closeSearch'
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
