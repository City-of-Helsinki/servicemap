define [
    'typeahead.bundle',
    'app/models',
    'app/jade',
    'app/search',
    'app/views/base',
], (
    typeahead,
    models,
    jade,
    search,
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
            'click .typeahead-suggestion.fulltext': 'executeQuery'
            'click .action-button.search-button': 'search'

        search: (e) ->
            e.stopPropagation()
            unless @isEmpty()
                @executeQuery()

        isEmpty: () ->
            query = @model.get 'input_query'
            if query? and query.length > 0
                return false
            return true
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

            streetDataset =
                source: search.geocoderStreetEngine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.getLanguage()]
                templates:
                    suggestion: (ctx) =>
                        ctx.object_type = 'address'
                        jade.template 'typeahead-suggestion', ctx

            street = undefined
            @listenTo search.searchEvents, 'response-received', (results) =>
                if results.length == 1
                    only = results[0]
                    if only.id == street?.id
                        return
                    street = only
                    street.translatedName = (
                        street.name[p13n.getLanguage()] or street.name.fi
                    ).toLowerCase()
                    street.addresses = new models.AddressList()
                    street.addressesFetched = false
                    street.addresses.fetch
                        data:
                            street: street.id
                            page_size: 200
                        success: =>
                            street.addressesFetched = true

            addressDataset =
                displayKey: (c) -> c.number
                templates:
                    suggestion: (c) ->
                        c.object_type = 'address'
                        c.set 'street', street
                        c.address = c.humanAddress()
                        jade.template 'typeahead-suggestion', c
                source: (query, callback) =>
                    if street?
                        re = new RegExp "^\\s*#{street.translatedName}\\s+(\\d.*)"
                        matches = query.match re
                        if matches?
                            [q, numberPart] = matches
                            numberPart = numberPart.replace /\s+/g, ''
                            done = =>
                                unless street? then callback []
                                filtered = street.addresses
                                    .filter (a) =>
                                        a.humanNumber().indexOf(numberPart) == 0
                                    .slice 0, 3
                                callback filtered
                            if street.addressesFetched
                                done()
                            else
                                @listenToOnce street.addresses, 'sync', =>
                                    done()
                        else
                            callback []

            # A hack needed to ensure the header is always rendered.
            fullDataset =
                name: 'header'
                # Source has to return non-empty list
                source: (q, c) -> c([{query: q, object_type: 'query'}])
                displayKey: (s) -> s.query
                name: 'full'
                templates:
                    suggestion: (s) -> jade.template 'typeahead-fulltext', s

            @$searchEl.typeahead hint: false, [
                fullDataset, streetDataset, addressDataset,
                serviceDataset, eventDataset]

            # On enter: was there a selection from the autosuggestions
            # or did the user hit enter without having selected a
            # suggestion?
            selected = false
            @$searchEl.on 'typeahead:selected', (ev) =>
                selected = true
            @$searchEl.on 'input', (ev) =>
                query = @getQuery()
                @model.set 'input_query', query,
                    initial: false,
                    keepOpen: true
                @searchResults.trigger 'hide'

            @$searchEl.focus (ev) =>
                @model.trigger 'change:input_query', @model, '', initial: true

            @$searchEl.keyup (ev) =>
                # Handle enter
                if ev.keyCode != 13
                    selected = false
                    return
                else if selected
                    # Skip autosuggestion selection with keyboard
                    selected = false
                    return
                @executeQuery()
        getQuery: () ->
            return $.trim @$searchEl.val()
        executeQuery: () ->
            @$searchEl.typeahead 'close'
            app.commands.execute 'search', @model.get 'input_query'
        autosuggestShowDetails: (ev, data, _) ->
            @$searchEl.typeahead 'val', ''
            app.commands.execute 'clearSearchResults', navigate: false
            $('.search-container input').val('')
            # Remove focus from the search box to hide keyboards on touch devices.
            $('.search-container input').blur()
            model = null
            objectType = data.object_type
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
                when 'address'
                    app.commands.execute 'selectPosition',
                        new models.AddressPosition(data)
