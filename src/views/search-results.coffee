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
    PAGE_SIZE = 10

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

    class SearchResultsLayoutView extends base.SMLayout
        template: 'search-results'
        regions:
            results: '.result-contents'
        className: 'search-results-container'
        events:
            'click .back-button': 'goBack'
            'click .show-more': 'nextPage'

        goBack: (ev) ->
            @parent.render()
        nextPage: (ev) ->
            @expansion += PAGE_SIZE
            @render()

        initialize: (opts) ->
            @expansion = EXPAND_CUTOFF
            @collection = opts.collection
            @fullCollection = @collection
            @resultType = opts.resultType
            @parent = opts.parent
            @listenTo @collection, 'hide', =>
                @hidden = true
                @render()
            @listenTo @collection, 'show-all', =>
                @expansion = PAGE_SIZE
                @render()
        serializeData: ->
            if @hidden
                return hidden: true
            data = super()
            if @collection.length
                data.header = i18n.t "sidebar.search_#{@resultType}_count",
                    count: @fullCollection.length
                data.showAll = null
                data.showMore = null
                if @fullCollection.length > EXPAND_CUTOFF and !@_expanded()
                    data.showAll = i18n.t "sidebar.search_#{@resultType}_show_all",
                        count: @fullCollection.length
                else if @fullCollection.length > @expansion
                    data.showMore = 'NÄYTTÄKEE LISSEE'
                data.target = @resultType
                data.expanded = @_expanded()
            data
        onRender: ->
            @results.show new SearchResultsView collection: @collection
            _.defer (=>
                $scrollElement = @$el.closest('.search-results')
                if $scrollElement
                    $scrollElement.scrollTop $scrollElement[0].scrollHeight)
        _expanded: ->
            @expansion > EXPAND_CUTOFF
        onBeforeRender: ->
            @collection = new models.SearchList @fullCollection.slice(0, @expansion)

    class SearchLayoutView extends base.SMLayout
        className: 'search-results navigation-element limit-max-height'
        template: 'search-layout'
        regions:
            servicePointResults: '.service-points'
            categoryResults: '.categories'
        type: 'search'
        events:
            'click .show-all': 'showAll'
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
                categoryResults = new SearchResultsLayoutView
                    resultType: 'category'
                    collection: @categoryCollection
                    parent: @
                @categoryResults.show categoryResults
            if @servicePointCollection.length
                servicePointResults = new SearchResultsLayoutView
                    resultType: 'service_point'
                    collection: @servicePointCollection
                    parent: @
                @servicePointResults.show servicePointResults


    SearchLayoutView
