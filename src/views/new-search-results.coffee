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
            @$el.html "<li id='search-unavailable-location-info'>#{i18n.t('search.location_info')}</li>"
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
                    app.request 'addService', @model, null
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
        triggers:
            'click .header-column-main': 'user:close'
            'click .collapse-button': @toggleCollapse
        initialize: ({@model, @collection, @fullCollection}) ->
            @expansion = 0
            if @collection.length == 0 then @nextPage()
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
        onDomRefresh: ->
            @$more = $(@el).find '.show-more'
            console.log @$more
        serializeData: ->
            if @hidden or not @collection?
                return hidden: true
            data = super()
            if @collection.length
                crumb = switch @collectionType
                    when 'search'
                        i18n.t('sidebar.search_results')
                    when 'radius'
                        if @position?
                            @position.humanAddress()
                data =
                    collapsed: @collapsed || false
                    comparatorKeys: @collection.getComparatorKeys()
                    comparatorKey: @collection.getComparatorKey()
                    controls: @collectionType == 'radius'
                    target: data.resultType
                    expanded: @collection.length > EXPAND_CUTOFF
                    showAll: false
                    showMore: false
                    onlyResultType: @onlyResultType
                    crumb: crumb
                    header: i18n.t("search.type.#{data.resultType}.count", count: @collection.length)
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
            @expansion = @expansion + PAGE_SIZE
            console.log @fullCollection?.length, @expansion

    class MoreButton extends base.SMItemView
        tagName: 'a'
        className: 'show-prompt show-all'
        template: 'search-results-more'
        events: ->
            'click .show-all': 'showAllOfSingleType'
        serializeData: ->
            data = super()
            showAll: i18n.t "search.type.#{data.type}.show_all",
                count: data.count
            target: data.type
        showAllOfSingleType: (ev) ->
            ev?.preventDefault()
            @trigger 'show-all', @model.get('type')

    class SearchResultsSummaryLayout extends base.SMLayout
        # showing a summary of search results of all model types
        template: 'new-search-layout'
        className: -> 'search-results navigation-element limit-max-height'
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
        onScroll: (ev) => @expandedView.onScroll(ev)
        initialize: ->
            @expanded = false
            @addRegion 'expandedRegion', '#expanded-region'
            @resultLayoutViews = {}
            @collections = {}
            @lengths = {}
        showAllOfSingleType: (target) ->
            @expanded = target
            @attachChildViews()
        onShow: ->
            @attachChildViews()
        attachChildViews: ->
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
                    collection: new RESULT_TYPES[@expanded](null, setComparator: true)
                    fullCollection: fullCollection
                region = @getRegion 'expandedRegion'
                region.show @expandedView
                @listenToOnce @expandedView, 'user:close', =>
                    @expanded = false
                    @attachChildViews()
                return
            else
                @expandedView = null
                _(RESULT_TYPES).each (ctor, key) =>
                    @collections[key] = new ctor(@_getArrayOfType(key, EXPAND_CUTOFF), setComparator: true)
                    @addRegion @_regionId(key), ".#{key}-region"
                    @addRegion @_regionId(key, 'more'), "##{key}-more"
                resultTypeCount = _(@collections).filter((c) => c.length > 0).length
                @getRegion('expandedRegion')?.empty()
                _(RESULT_TYPES).each (__, key) =>
                    if @collections[key].length
                        @resultLayoutViews[key] = new SearchResultsCompositeView
                            model: new Backbone.Model
                                resultType: key
                                collectionType: 'search'
                                onlyResultType: resultTypeCount == 1
                                parent: @
                            collection: @collections[key]
                        @_getRegionForType(key)?.show @resultLayoutViews[key]
                        moreButton = new MoreButton
                            model: new Backbone.Model
                                type: key
                                count: @lengths[key]
                        @_getRegionForType(key, 'more')?.show moreButton
                        @listenTo moreButton, 'show-all', @showAllOfSingleType

    {SearchResultsSummaryLayout}
