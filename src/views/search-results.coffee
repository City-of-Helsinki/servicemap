define [
    'underscore',
    'i18next',
    'cs!app/models',
    'cs!app/views/base',
    'cs!app/views/radius',
    'cs!app/spinner'
], (
    _,
    i18n,
    models,
    base,
    RadiusControlsView,
    SMSpinner
) ->

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
      return rect.bottom <= (window.innerHeight or document.documentElement.clientHeight) + (el.offsetHeight * 0)


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
                    app.commands.execute 'selectUnit', @model
                when 'service'
                    app.commands.execute 'addService', @model
                when 'address'
                    app.commands.execute 'selectPosition', @model

        highlightResult: (ev) ->
            app.commands.execute 'highlightUnit', @model

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

    class SearchResultsView extends base.SMCollectionView
        tagName: 'ul'
        className: 'main-list'
        itemView: SearchResultView
        itemViewOptions: ->
            order: @parent.getComparatorKey()
            selectedServices: @parent.selectedServices
        initialize: (opts) ->
            super opts
            @parent = opts.parent

    class LocationPromptView extends base.SMItemView
        tagName: 'ul'
        className: 'main-list'
        render: ->
            @$el.html "<li id='search-unavailable-location-info'>#{i18n.t('search.location_info')}</li>"
            @

    class SearchResultsLayoutView extends base.SMLayout
        template: 'search-results'
        regions:
            results: '.result-contents'
            controls: '#list-controls'
        className: 'search-results-container'
        events:
            'click .back-button': 'goBack'
            'click .sort-item': 'setComparatorKey'
            'click .collapse-button': 'toggleCollapse'

        goBack: (ev) ->
            @expansion = EXPAND_CUTOFF
            @requestedExpansion = 0
            @parent.backToSummary()

        setComparatorKey: (ev) ->
            key = $(ev.currentTarget).data('sort-key')
            @renderLocationPrompt = false
            if key is 'distance'
                unless p13n.getLastPosition()?
                    @renderLocationPrompt = true
                    @listenTo p13n, 'position', =>
                        @renderLocationPrompt = false
                        @fullCollection.sort()
                    @listenTo p13n, 'position_error', =>
                        @renderLocationPrompt = false
                    p13n.requestLocation()
            @expansion = 2 * PAGE_SIZE
            @fullCollection.reSort(key)

        getComparatorKey: ->
            @fullCollection.getComparatorKey()

        onBeforeRender: ->
            @collection = new @fullCollection.constructor @fullCollection.slice(0, @expansion)

        nextPage: (ev) ->
            if @expansion == EXPAND_CUTOFF
                # Initial expansion
                delta = 2 * PAGE_SIZE - EXPAND_CUTOFF
            else
                # Already expanded, next page
                delta = PAGE_SIZE
            newExpansion = @expansion + delta

            # Only handle repeated scroll events once.
            if @requestedExpansion == newExpansion then return
            @requestedExpansion = newExpansion

            @expansion = @requestedExpansion
            @render()

        getDetailedFieldset: ->
            switch @resultType
                when 'unit'
                    ['services']
                when 'service'
                    ['ancestors']
                else
                    null

        initialize: ({
            collectionType: @collectionType
            fullCollection: @fullCollection
            resultType: @resultType
            parent: @parent
            onlyResultType: @onlyResultType
            position: @position
            selectedServices: @selectedServices
        }) ->
            @expansion = EXPAND_CUTOFF
            @$more = null
            @requestedExpansion = 0
            @ready = false
            @ready = true
            if @onlyResultType
                @expansion = 2 * PAGE_SIZE
                @parent?.expand @resultType
            @listenTo @fullCollection, 'hide', =>
                @hidden = true
                @render()
            @listenTo @fullCollection, 'show-all', @nextPage
            @listenTo @fullCollection, 'sort', @render
            @listenTo @fullCollection, 'batch-remove', @render
            @listenTo p13n, 'accessibility-change', =>
                key = @fullCollection.getComparatorKey()
                if p13n.hasAccessibilityIssues()
                    @fullCollection.setComparator 'accessibility'
                else if key == 'accessibility'
                    @fullCollection.setDefaultComparator()
                @fullCollection.sort()
                @render()

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
                    comparatorKeys: @fullCollection.getComparatorKeys()
                    comparatorKey: @fullCollection.getComparatorKey()
                    controls: @collectionType == 'radius'
                    target: @resultType
                    expanded: @_expanded()
                    showAll: false
                    showMore: false
                    onlyResultType: @onlyResultType
                    crumb: crumb
                    header: i18n.t("search.type.#{@resultType}.count", count: @fullCollection.length)
                if @fullCollection.length > EXPAND_CUTOFF and !@_expanded()
                    data.showAll = i18n.t "search.type.#{@resultType}.show_all",
                        count: @fullCollection.length
                else if @fullCollection.length > @expansion and not @renderLocationPrompt
                    data.showMore = true
            data

        onRender: ->
            if @renderLocationPrompt
                @results.show new LocationPromptView()
                return
            unless @ready
                @ready = true
                return
            collectionView = new SearchResultsView
                collection: @collection
                parent: @
            @listenTo collectionView, 'collection:rendered', =>
                _.defer =>
                    @$more = $(@el).find '.show-more'
                    # Just in case the initial long list somehow
                    # fits inside the page:
                    @tryNextPage()
                    @trigger 'rendered'
            @results.show collectionView
            if @collectionType == 'radius'
                @controls.show new RadiusControlsView radius: @fullCollection.filters.distance

        tryNextPage: ->
            if @$more?.length
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

        _expanded: ->
            @expansion > EXPAND_CUTOFF

    class BaseListingLayoutView extends base.SMLayout
        className: -> 'search-results navigation-element limit-max-height'
        events: ->
            'scroll': 'tryNextPage'
        onRender: ->
            view = @getPrimaryResultLayoutView()
            unless view?
                return
            @listenToOnce view, 'rendered', =>
                _.defer => @$el.find('.search-result').first().focus()

    class UnitListLayoutView extends BaseListingLayoutView
        template: 'service-units'
        regions:
            'unitRegion': '.unit-region'
        tryNextPage: ->
            @resultLayoutView.tryNextPage()
        initialize: (opts, rest...) ->
            @resultLayoutView = new SearchResultsLayoutView opts, rest...
        onRender: ->
            @unitRegion.show @resultLayoutView
            super()
        getPrimaryResultLayoutView: ->
            @resultLayoutView

    class SearchLayoutView extends BaseListingLayoutView
        template: 'search-layout'
        type: 'search'
        events: ->
            _.extend {}, super(), 'click .show-all': 'showAllOfSingleType'
        tryNextPage: ->
            if @expanded
                @resultLayoutViews[@expanded]?.tryNextPage()
        expand: (target) ->
            @expanded = target
        showAllOfSingleType: (ev) ->
            ev?.preventDefault()
            target = $(ev.currentTarget).data 'target'
            @expanded = target
            _(@collections).each (collection, key) =>
                if key == target
                    collection.trigger 'show-all'
                else
                    collection.trigger 'hide'
        backToSummary: ->
            @expanded = null
            @render()

        _regionId: (key) ->
            "#{key}Region"
        _getRegionForType: (key) ->
            @getRegion @_regionId(key)

        initialize: ->
            @expanded = null
            @collections = {}
            @resultLayoutViews = {}

            _(RESULT_TYPES).each (val, key) =>
                @collections[key] = new val(null, setComparator: true)
                @addRegion @_regionId(key), ".#{key}-region"

            @listenTo @collection, 'hide', => @$el.hide()

        serializeData: ->
            data = super()
            _(RESULT_TYPES).each (__, key) =>
                @collections[key].set @collection.where(object_type: key)
            #@collections.unit.sort()

            unless @collection.length
                if @collection.query
                    data.noResults = true
                    data.query = @collection.query
            data

        getPrimaryResultLayoutView: ->
            @resultLayoutViews['unit']

        onRender: ->
            @$el.show()
            resultTypeCount = _(@collections).filter((c) => c.length > 0).length
            _(RESULT_TYPES).each (__, key) =>
                if @collections[key].length
                    @resultLayoutViews[key] = new SearchResultsLayoutView
                        resultType: key
                        collectionType: 'search'
                        fullCollection: @collections[key]
                        onlyResultType: resultTypeCount == 1
                        parent: @
                    @_getRegionForType(key).show @resultLayoutViews[key]
            super()

    SearchLayoutView: SearchLayoutView
    UnitListLayoutView: UnitListLayoutView
