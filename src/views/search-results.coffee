define ->

    class SearchResultsView extends base.SMCollectionView
        itemView: SearchResultView

    class SearchResultView extends base.SMItemView
        tagName: 'li'
        events:
            'click': 'select_result'
            'mouseenter': 'highlight_result'
        template: 'search-result'

        select_result: (ev) ->
            if @model.get('object_type') == 'unit'
                app.commands.execute 'selectUnit', @model
            else if @model.get('object_type') == 'service'
                app.commands.execute 'addService', @model

        highlight_result: (ev) ->
            app.commands.execute 'highlightUnit', @model

        serializeData: ->
            data = super()
            data.specifier_text = @model.get_specifier_text()
            data


    class SearchLayoutView extends base.SMLayout
        className: 'search-results navigation-element limit-max-height'
        template: 'search-results'
        events:
            'click .show-all': 'show_all'
        type: 'search'

        initialize: ->
            @category_collection = new models.SearchList()
            @service_point_collection = new models.SearchList()
            @listenTo @collection, 'add', _.debounce(@update_results, 10)
            @listenTo @collection, 'remove', _.debounce(@update_results, 10)
            @listenTo @collection, 'reset', @update_results
            @listenTo @collection, 'ready', @update_results
            @listenTo @collection, 'hide', => @$el.hide()

        show_all: (ev) ->
            ev?.preventDefault()
            console.log 'show all!'
            # TODO: Add functionality for querying and showing all results here.

        update_results: ->
            @$el.show()
            @category_collection.set @collection.where(object_type: 'service')
            @service_point_collection.set @collection.where(object_type: 'unit')
            @$('.categories, .categories + .show-all').addClass('hidden')
            @$('.service-points, .service-points + .show-all').addClass('hidden')

            if @category_collection.length
                header_text = i18n.t('sidebar.search_category_count', {count: @category_collection.length})
                show_all_text = i18n.t('sidebar.search_category_show_all', {count: @category_collection.length})
                @$('.categories, .categories + .show-all').removeClass('hidden')
                @$('.categories .header-item').text(header_text)
                @$('.categories + .show-all').text(show_all_text)

            if @service_point_collection.length
                header_text = i18n.t('sidebar.search_service_point_count', {count: @service_point_collection.length})
                show_all_text = i18n.t('sidebar.search_service_point_show_all', {count: @service_point_collection.length})
                @$('.service-points, .service-points + .show-all').removeClass('hidden')
                @$('.service-points .header-item').text(header_text)
                @$('.service-points + .show-all').text(show_all_text)

        onRender: ->
            @category_results = new SearchResultsView
                collection: @category_collection
                el: @$('.categories')
            @service_point_results = new SearchResultsView
                collection: @service_point_collection
                el: @$('.service-points')
            if @collection.length
                @update_results()


    SearchLayoutView
