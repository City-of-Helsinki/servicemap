define [
    'typeahead.bundle',
    'app/models',
    'app/jade',
    'app/search',
    'app/geocoding',
    'app/views/base',
], (
    typeahead,
    models,
    jade,
    search,
    geocoding,
    base
) ->
    class SearchInputView extends base.SMItemView
        classname: 'search-input-element'
        template: 'navigation-search'
        initialize: (@model, @searchResults) ->
            @listenTo @model, 'change:input_query', @adaptToQuery
            @listenTo @searchResults, 'ready', @adaptToQuery
        adaptToQuery: (model, value, opts) ->
            $container = @$el.find('.action-button')
            $icon = $container.find('span')
            if opts? and (opts.initial or opts.clearing)
                @$searchEl.val @model.get('input_query')
            if @isEmpty()
                if @searchResults.query
                    if opts? and opts.initial
                        @model.set 'input_query', @searchResults.query,
                            initial: false
            if @isEmpty() or @model.get('input_query') == @searchResults.query
                $icon.removeClass 'icon-icon-forward-bold'
                $icon.addClass 'icon-icon-close'
                $container.removeClass 'search-button'
                $container.addClass 'close-button'
            else
                $icon.addClass 'icon-icon-forward-bold'
                $icon.removeClass 'icon-icon-close'
                $container.removeClass 'close-button'
                $container.addClass 'search-button'
        events:
            'typeahead:selected': 'autosuggestShowDetails'
            # Important! The following ensures the click
            # will only cause the intended typeahead selection.
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click input': '_onInputClicked'
            'click .typeahead-suggestion.fulltext': 'executeQuery'
            'click .action-button.search-button': 'search'
            'submit .input-container': 'search'

        search: (e) ->
            e.stopPropagation()
            unless @isEmpty()
                @$searchEl.typeahead 'close'
                @executeQuery()
            e.preventDefault()

        isEmpty: () ->
            query = @model.get 'input_query'
            if query? and query.length > 0
                return false
            return true
        _onInputClicked: (ev) ->
            @trigger 'open'
            ev.stopPropagation()
        onRender: () ->
            @enableTypeahead('input.form-control[type=search]')
            @setTypeaheadWidth()
            $(window).resize => @setTypeaheadWidth()
        setTypeaheadWidth: ->
            windowWidth = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
            if windowWidth < appSettings.mobile_ui_breakpoint
                width = $('#navigation-header').width()
                @$el.find('.tt-dropdown-menu').css 'width': width
            else
                @$el.find('.tt-dropdown-menu').css 'width': 'auto'
        enableTypeahead: (selector) ->
            @$searchEl = @$el.find selector
            serviceDataset =
                name: 'service'
                source: search.servicemapEngine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.getLanguage()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
            eventDataset =
                name: 'event'
                source: search.linkedeventsEngine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.getLanguage()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx


            # A hack needed to ensure the header is always rendered.
            fullDataset =
                name: 'header'
                # Source has to return non-empty list
                source: (q, c) -> c([{query: q, object_type: 'query'}])
                displayKey: (s) -> s.query
                name: 'full'
                templates:
                    suggestion: (s) -> jade.template 'typeahead-fulltext', s

            @geocoderBackend = new geocoding.GeocoderSourceBackend()
            @$searchEl.typeahead hint: false, [
                fullDataset,
                @geocoderBackend.getDatasetOptions(),
                serviceDataset,
                eventDataset]
            @geocoderBackend.setOptions
                $inputEl: @$searchEl
                selectionCallback: (ev, data) ->
                    app.commands.execute 'selectPosition', data

            @$searchEl.on 'input', (ev) =>
                query = @getQuery()
                @model.set 'input_query', query,
                    initial: false,
                    keepOpen: true
                @searchResults.trigger 'hide'

            # TODO: works for mobile, messes everything else
            # @$searchEl.focus (ev) =>
            #     @model.trigger 'change:input_query', @model, '', initial: true

        getQuery: () ->
            return $.trim @$searchEl.val()
        executeQuery: () ->
            @geocoderBackend.street = null
            @$searchEl.typeahead 'close'
            app.commands.execute 'search', @model.get 'input_query'
        autosuggestShowDetails: (ev, data, _) ->
            # Remove focus from the search box to hide keyboards on touch devices.
            # TODO: re-enable in a compatible way
            #$('.search-container input').blur()
            model = null
            objectType = data.object_type
            if objectType == 'address'
                return
            @$searchEl.typeahead 'val', ''
            app.commands.execute 'clearSearchResults', navigate: false
            $('.search-container input').val('')
            @$searchEl.typeahead 'close'
            switch objectType
                when 'unit'
                    model = new models.Unit(data)
                    app.commands.execute 'selectUnit', model, replace: true
                when 'service'
                    app.commands.execute 'addService',
                        new models.Service(data)
                when 'event'
                    app.commands.execute 'selectEvent',
                        new models.Event(data)
                when 'query'
                    app.commands.execute 'search', data.query
