define (require) ->

    _                  = require 'underscore'
    i18n               = require 'i18next'
    Backbone           = require 'backbone'

    models             = require 'cs!app/models'
    base               = require 'cs!app/views/base'
    RadiusControlsView = require 'cs!app/views/radius'
    SMSpinner          = require 'cs!app/spinner'

    RESULT_TYPES =
        unit: models.UnitList
        service: models.ServiceList
        # event: models.EventList
        address: models.PositionList

    EXPAND_CUTOFF = 3
    PAGE_SIZE = 20

    isElementInViewport = (el) ->
        if typeof jQuery == 'function' and el instanceof jQuery
            el = el[0]
        rect = el.getBoundingClientRect()
        return rect.bottom <= (window.innerHeight or document.documentElement.clientHeight) + (el.offsetHeight * 0.5)

    class LocationPromptView extends base.SMItemView
        tagName: 'ul'
        className: 'main-list'
        render: ->
            @$el.html "<li id='search-unavailable-location-info'>#{}</li>"
            @

    class SearchResultView extends base.SMItemView
        template: 'search-result'
        tagName: 'li'
        events: ->
            keyhandler = @keyboardHandler @selectResult, ['enter']
            'click': 'selectResult'
            'keydown': keyhandler
            'focus': 'highlightResult'
            'mouseenter': 'highlightResult'
        initialize: (opts) ->
            @order = opts.order
            @selectedServices = opts.selectedServices
        selectResult: (ev) ->
            object_type = @model.get('object_type') or 'unit'
            switch object_type
                when 'unit'
                    app.request 'selectUnit', @model, {}
                when 'service'
                    app.request 'addService', @model, {}
                when 'address'
                    app.request 'selectPosition', @model

        highlightResult: (ev) ->
            app.request 'highlightUnit', @model

        serializeData: ->
            data = super()
            # the selected services must be passed on to the model so we get proper specifier
            data.specifier_text = @model.getSpecifierText(@selectedServices)
            switch @order
                when 'distance'
                    fn = @model.getDistanceToLastPosition
                    if fn?
                        data.distance = fn.apply @model
                when 'accessibility'
                    fn = @model.getShortcomingCount
                    if fn?
                        data.shortcomings = fn.apply @model
            if @model.get('object_type') == 'address'
                data.name = @model.humanAddress exclude: municipality: true
            data

    class SearchResultsCompositeView extends base.SMCompositeView
        template: 'new-search-results'
        childView: SearchResultView
        childViewContainer: '.search-result-list'
        childViewOptions: ->
            order: @fullCollection?.getComparatorKey()
            selectedServices: @selectedServices
        events:
            'click .sort-item': 'setComparatorKey'
            'click .collapse-button': 'toggleCollapse'
        triggers:
            'click .back-button': 'user:close'
        initialize: ({@model, @collection, @fullCollection, @selectedServices}) ->
            @expansion = 0
            if @collection.length == 0 then @nextPage()
            @listenTo p13n, 'accessibility-change', =>
                key = @fullCollection.getComparatorKey()
                if p13n.hasAccessibilityIssues()
                    @fullCollection.setComparator 'accessibility'
                else if key == 'accessibility'
                    @fullCollection.setDefaultComparator()
                @fullCollection.sort()
                @render()
            @listenTo @fullCollection, 'finished', =>
                @expansion = 0
                @nextPage()
        onDomRefresh: ->
            @$more = $(@el).find '.show-more'
        toggleCollapse: ->
            @collapsed = !@collapsed
            if @collapsed
                @$el.find('.result-contents').hide()
                @$el.find('.show-prompt').hide()
            else
                @$el.find('.result-contents').show()
                @$el.find('.show-prompt').show()
        onScroll: ->
            return unless @$more?.length
            if isElementInViewport @$more
                @$more.find('.text-content').html i18n.t('accessibility.pending')
                spinner = new SMSpinner
                    container: @$more.find('.spinner-container').get(0),
                    radius: 5,
                    length: 3,
                    lines: 12,
                    width: 2,
                spinner.start()
                @nextPage()
        setComparatorKey: (ev) ->
            key = $(ev.currentTarget).data('sort-key')
            @renderLocationPrompt = false
            executeComparator = =>
                @collection.reset [], silent: true
                @fullCollection.reSort key
                @expansion = 0
                @nextPage()
                @render()
            if key is 'distance'
                unless p13n.getLastPosition()?
                    @renderLocationPrompt = true
                    @listenTo p13n, 'position', =>
                        @renderLocationPrompt = false
                        executeComparator()
                    @listenTo p13n, 'position_error', =>
                        @renderLocationPrompt = false
                    @render()
                    p13n.requestLocation()
                    return
            executeComparator()
        serializeData: ->
            if @hidden or not @collection?
                return hidden: true
            data = super()
            if @collection.length
                crumb = switch data.collectionType
                    when 'search'
                        i18n.t('sidebar.search_results')
                    when 'radius'
                        if data.position?
                            data.position.humanAddress()
                data =
                    collapsed: @collapsed || false
                    comparatorKeys: @fullCollection?.getComparatorKeys()
                    comparatorKey: @fullCollection?.getComparatorKey()
                    target: data.resultType
                    expanded: @collection.length > EXPAND_CUTOFF
                    locationPrompt: if @renderLocationPrompt then i18n.t('search.location_info') else null
                    showMore: false
                    onlyResultType: @onlyResultType
                    crumb: crumb
                    header: i18n.t("search.type.#{data.resultType}.count", count: data.count)
                    showAll: i18n.t "search.type.#{data.resultType}.show_all",
                        count: @collection.length
            if @fullCollection?.length > @expansion and not @renderLocationPrompt
                data.showMore = true
            data
        nextPage: ->
            if @expansion > @fullCollection.length
                @render()
                return
            @collection.add @fullCollection.slice(@expansion, @expansion + PAGE_SIZE)
            window.c = @collection
            @expansion = @expansion + PAGE_SIZE

    class MoreButton extends base.SMItemView
        tagName: 'a'
        className: 'show-prompt show-all'
        attributes: href: '#!'
        getTemplate: -> ({type, count}) =>
            i18n.t "search.type.#{type}.show_all", count: count
        triggers: 'click': 'show-all'

    class UnitListingView extends base.SMLayout
        template: 'unit-list'
        className: 'search-results navigation-element limit-max-height'
        events: 'scroll': 'onScroll'
        regions:
            unitListRegion: '#unit-list-region'
            controls: '#list-controls'
        initialize: ({@model, @collection, @fullCollection, @selectedServices, @services}) ->
            @listenTo @fullCollection, 'finished', @render
        onScroll: (event) -> @view?.onScroll event
        serializeData: ->
            controls: @model.get('collectionType') == 'radius'
        onShow: ->
            @view = new SearchResultsCompositeView
                model: @model
                collection: new models.UnitList null, setComparator: false
                fullCollection: @fullCollection
                selectedServices: @selectedServices
            @unitListRegion.show @view
            @listenToOnce @view, 'user:close', =>
                @unitListRegion.empty()
                if @services?
                    @services.trigger 'finished'
                else if @model.get 'position'
                    app.request 'clearRadiusFilter'
            if @model.get('collectionType') == 'radius'
                @controls.show new RadiusControlsView radius: @fullCollection.filters.distance
    class SearchResultsSummaryLayout extends base.SMLayout
        # showing a summary of search results of all model types
        template: 'new-search-layout'
        className: 'search-results navigation-element limit-max-height'
        events:
            'scroll': 'onScroll'
        _regionId: (key, suffix) ->
            suffix = '' unless suffix?
            "#{key}Region#{suffix}"
        _getRegionForType: (key, suffix) ->
            @getRegion @_regionId(key, suffix)
        _getArrayOfType: (key, size) ->
            arr = @collection.where object_type: key
            @lengths[key] = arr.length
            return arr unless size
            arr.slice 0, size
        onScroll: (ev) => @expandedView?.onScroll(ev)
        disableAutoFocus: ->
            @autoFocusDisabled = true
        initialize: ({@collection, @fullCollection, @collectionType, @resultType, @onlyResultType, @selectedServices}) ->
            @expanded = false
            @addRegion 'expandedRegion', '#expanded-region'
            @resultLayoutViews = {}
            @collections = {}
            @lengths = {}
        showAllOfSingleType: (opts) ->
            target = opts.model.get 'type'
            @expanded = target
            @showChildViews()
        onShow: ->
            @showChildViews()
        onDomRefresh: ->
            view = @expandedView or _.values(@resultLayoutViews)[0]
            return unless view?
            #TODO test
        showChildViews: ->
            if @expanded
                _(RESULT_TYPES).each (ctor, key) =>
                    region = @_getRegionForType key
                    moreRegion = @_getRegionForType key, 'more'
                    region?.empty()
                    moreRegion?.empty()
                fullCollection = new RESULT_TYPES[@expanded](@_getArrayOfType(@expanded), setComparator: true)
                @expandedView = new SearchResultsCompositeView
                    model: new Backbone.Model
                        resultType: @expanded
                        collectionType: 'search'
                        onlyResultType: true
                        parent: @
                        count: fullCollection.length
                    collection: new RESULT_TYPES[@expanded](null, setComparator: false)
                    fullCollection: fullCollection
                    selectedServices: @selectedServices
                region = @getRegion 'expandedRegion'
                unless @autoFocusDisabled
                    @listenToOnce @expandedView, 'render', =>
                        _.defer => @$el.find('.search-result').first().focus()
                region.show @expandedView
                @listenToOnce @expandedView, 'user:close', =>
                    @expanded = false
                    @showChildViews()
                return
            else
                @expandedView = null
                _(RESULT_TYPES).each (ctor, key) =>
                    @collections[key] = new ctor(@_getArrayOfType(key, EXPAND_CUTOFF), setComparator: true)
                    @addRegion @_regionId(key), ".#{key}-region"
                    @addRegion @_regionId(key, 'more'), "##{key}-more"
                resultTypeCount = _(@collections).filter((c) => c.length > 0).length
                @getRegion('expandedRegion')?.empty()
                done = false
                _(RESULT_TYPES).each (__, key) =>
                    if @collections[key].length
                        view = new SearchResultsCompositeView
                            model: new Backbone.Model
                                resultType: key
                                collectionType: 'search'
                                onlyResultType: resultTypeCount == 1
                                parent: @
                                count: @lengths[key]
                            collection: @collections[key]
                            selectedServices: @selectedServices
                        @resultLayoutViews[key] = view
                        unless @autoFocusDisabled
                            unless done
                                done = true
                                @listenToOnce view, 'render', =>
                                    _.defer => @$el.find('.search-result').first().focus()
                        @_getRegionForType(key)?.show view
                        if @lengths[key] > EXPAND_CUTOFF
                            moreButton = new MoreButton
                                model: new Backbone.Model
                                    type: key
                                    count: @lengths[key]
                            @_getRegionForType(key, 'more')?.show moreButton
                            @listenTo moreButton, 'show-all', @showAllOfSingleType
                @autoFocusDisabled = false

    {SearchResultsSummaryLayout, UnitListingView}
