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
        tagName: 'li'
        events:
            'click': 'selectResult'
            'mouseenter': 'highlightResult'
        template: 'search-result'

        selectResult: (ev) ->
            if @model.get('object_type') == 'unit'
                app.commands.execute 'selectUnit', @model
            else if @model.get('object_type') == 'service'
                app.commands.execute 'addService', @model

        highlightResult: (ev) ->
            app.commands.execute 'highlightUnit', @model

        serializeData: ->
            data = super()
            data.specifier_text = @model.getSpecifierText()
            data

    class SearchResultsView extends base.SMCollectionView
        itemView: SearchResultView


    class SearchLayoutView extends base.SMLayout
        className: 'search-results navigation-element limit-max-height'
        template: 'search-results'
        events:
            'click .show-all': 'showAll'
        type: 'search'

        initialize: ->
            @categoryCollection = new models.SearchList()
            @servicePointCollection = new models.SearchList()
            @listenTo @collection, 'add', _.debounce(@updateResults, 10)
            @listenTo @collection, 'remove', _.debounce(@updateResults, 10)
            @listenTo @collection, 'reset', @updateResults
            @listenTo @collection, 'ready', @updateResults
            @listenTo @collection, 'hide', => @$el.hide()

        showAll: (ev) ->
            ev?.preventDefault()
            console.log 'show all!'
            # TODO: Add functionality for querying and showing all results here.

        updateResults: ->
            @$el.show()
            @categoryCollection.set @collection.where(object_type: 'service')
            @servicePointCollection.set @collection.where(object_type: 'unit')
            @$('.categories, .categories + .show-all').addClass('hidden')
            @$('.service-points, .service-points + .show-all').addClass('hidden')

            if @categoryCollection.length
                headerText = i18n.t('sidebar.search_category_count', {count: @categoryCollection.length})
                showAllText = i18n.t('sidebar.search_category_show_all', {count: @categoryCollection.length})
                @$('.categories, .categories + .show-all').removeClass('hidden')
                @$('.categories .header-item').text(headerText)
                @$('.categories + .show-all').text(showAllText)

            if @servicePointCollection.length
                headerText = i18n.t('sidebar.search_service_point_count', {count: @servicePointCollection.length})
                showAllText = i18n.t('sidebar.search_service_point_show_all', {count: @servicePointCollection.length})
                @$('.service-points, .service-points + .show-all').removeClass('hidden')
                @$('.service-points .header-item').text(headerText)
                @$('.service-points + .show-all').text(showAllText)

        onRender: ->
            @categoryResults = new SearchResultsView
                collection: @categoryCollection
                el: @$('.categories')
            @servicePointResults = new SearchResultsView
                collection: @servicePointCollection
                el: @$('.service-points')
            if @collection.length
                @updateResults()


    SearchLayoutView
