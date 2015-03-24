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
        className: '.search-results-container'
        initialize: (opts) ->
            @expanded = false
            @collection = opts.collection
            @fullCollection = null
            @resultType = opts.resultType
            @listenTo @collection, 'hide', =>
                @hidden = true
                @render()
            @listenTo @collection, 'show-all', =>
                @expanded = true
                @render()
        serializeData: ->
            if @hidden
                return hidden: true
            data = super()
            if @collection.length
                data.header = i18n.t "sidebar.search_#{@resultType}_count",
                    count: @collection.length
                data.showAll = i18n.t "sidebar.search_#{@resultType}_show_all",
                    count: @collection.length
                data.target = @resultType
                data.expanded = @expanded
            data
        onRender: ->
            @results.show new SearchResultsView collection: @collection
        onBeforeRender: ->
            if @expanded
                if @fullCollection
                    @collection = @fullCollection
            else
                @fullCollection = @collection
                @collection = new models.SearchList @fullCollection.slice(0, 3)

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
            targetView = $(ev.currentTarget).data('target')
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
            # @listenTo @collection, 'add', _.debounce(@updateResults, 10)
            # @listenTo @collection, 'remove', _.debounce(@updateResults, 10)
            # @listenTo @collection, 'reset', @updateResults
            #@listenTo @collection, 'ready', @render

        serializeData: ->
            data = super()
            @categoryCollection.set @collection.where(object_type: 'service')
            @servicePointCollection.set @collection.where(object_type: 'unit')
            data

        onRender: ->
            categoryResults = new SearchResultsLayoutView
                resultType: 'category'
                collection: @categoryCollection
            servicePointResults = new SearchResultsLayoutView
                resultType: 'service_point'
                collection: @servicePointCollection
            @servicePointResults.show servicePointResults
            @categoryResults.show categoryResults


    SearchLayoutView
