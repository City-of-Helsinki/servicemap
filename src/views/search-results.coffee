define [
    'underscore',
    'i18next',
    'app/models',
    'app/views/base',
], (
    _,
    i18n,
    models,
    base
) ->

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
        events:
            'click': 'selectResult'
            'mouseenter': 'highlightResult'

        selectResult: (ev) ->
            if @model.get('object_type') == 'unit'
                app.commands.execute 'selectUnit', @model
            else if @model.get('object_type') == 'service'
                app.commands.execute 'addService', @model

        highlightResult: (ev) ->
            app.commands.execute 'highlightUnit', @model

        serializeData: ->
            data = super()
            # TODO: re-enable
            #data.specifier_text = @model.getSpecifierText()
            data.specifier_text = ''
            data

    class SearchResultsView extends base.SMCollectionView
        tagName: 'ul'
        className: 'main-list'
        itemView: SearchResultView
        initialize: (opts) ->
            super(opts)
            @parent = opts.parent

    class SearchResultsLayoutView extends base.SMLayout
        template: 'search-results'
        regions:
            results: '.result-contents'
        className: 'search-results-container'
        events:
            'click .back-button': 'goBack'

        goBack: (ev) ->
            @parent.render()
        nextPage: (ev) ->
            newExpansion = @expansion + PAGE_SIZE
            if @requestedExpansion == newExpansion
                return
            @requestedExpansion = newExpansion
            #@collection.getDetails(0, @expansion, ['services'])
            _.delay (=>
                @expansion = @requestedExpansion
                @render()), 600

        initialize: (opts) ->
            @expansion = EXPAND_CUTOFF
            @collection = opts.collection
            @fullCollection = @collection
            @resultType = opts.resultType
            @parent = opts.parent
            @$more = null
            @requestedExpansion = 0
            #@nextPage = _.debounce _.bind(@nextPage, @), 500

            @listenTo @collection, 'hide', =>
                @hidden = true
                @render()
            @listenTo @collection, 'show-all', =>
                @expansion = PAGE_SIZE
                @collection.getDetails(0, @expansion, ['services'])
                @render()
        serializeData: ->
            if @hidden
                return hidden: true
            data = super()
            if @collection.length
                data =
                    target: @resultType
                    expanded: @_expanded()
                    showAll: false
                    showMore: false
                    header: i18n.t "sidebar.search_#{@resultType}_count", count: @fullCollection.length
                if @fullCollection.length > EXPAND_CUTOFF and !@_expanded()
                    data.showAll = i18n.t "sidebar.search_#{@resultType}_show_all",
                        count: @fullCollection.length
                else if @fullCollection.length > @expansion
                    data.showMore = true
            data

        onRender: ->
            view = new SearchResultsView collection: @collection, parent: @
            @listenTo view, 'collection:rendered', =>
                _.defer => @$more = $(@el).find '.show-more'
            @results.show view

        tryNextPage: ->
            if @$more?.length
                if isElementInViewport @$more
                    @$more.html i18n.t('accessibility.pending')
                    @nextPage()

        _expanded: ->
            @expansion > EXPAND_CUTOFF
        onBeforeRender: ->
            @collection = new models.SearchList @fullCollection.slice(0, @expansion)

    class SearchLayoutView extends base.SMLayout
        className: 'search-results navigation-element limit-max-height'
        template: 'search-layout'
        regions:
            servicePointResultsRegion: '.service-points'
            categoryResultsRegion: '.categories'
        type: 'search'
        events:
            'click .show-all': 'showAll'
            'scroll': 'tryNextPage'
        tryNextPage: ->
            @servicePointResults?.tryNextPage()
        showAll: (ev) ->
            ev?.preventDefault()
            targetView = $(ev.currentTarget).data 'target'
            targetCollection = null
            switch targetView
                when 'category'
                    targetCollection = @categoryCollection
                    otherCollection = @servicePointCollection
                when 'service_point'
                    targetCollection = @servicePointCollection
                    otherCollection = @categoryCollection
            otherCollection.trigger 'hide'
            targetCollection.trigger 'show-all'

        initialize: ->
            @categoryCollection = new models.SearchList()
            @servicePointCollection = new models.SearchList()
            @listenTo @collection, 'hide', => @$el.hide()
            @listenTo @collection, 'ready', @render

        serializeData: ->
            data = super()
            @categoryCollection.set @collection.where(object_type: 'service')
            @servicePointCollection.set @collection.where(object_type: 'unit')
            data

        onRender: ->
            if @categoryCollection.length
                @categoryResults = new SearchResultsLayoutView
                    resultType: 'category'
                    collection: @categoryCollection
                    parent: @
                @categoryResultsRegion.show @categoryResults
            if @servicePointCollection.length
                @servicePointResults = new SearchResultsLayoutView
                    resultType: 'service_point'
                    collection: @servicePointCollection
                    parent: @
                @servicePointResultsRegion.show @servicePointResults


    SearchLayoutView

