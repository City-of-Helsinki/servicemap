define ->

    class SearchInputView extends base.SMItemView
        classname: 'search-input-element'
        template: 'navigation-search'
        initialize: (@model, @search_results) ->
            @listenTo @model, 'change:input_query', @adapt_to_query
            @listenTo @search_results, 'ready', @adapt_to_query
        adapt_to_query: (model, value, opts) ->
            $container = @$el.find('.action-button')
            $icon = $container.find('span')
            if opts? and (opts.initial or opts.clearing)
                @$search_el.val @model.get('input_query')
            if @is_empty()
                if @search_results.query
                    if opts? and opts.initial
                        @model.set 'input_query', @search_results.query,
                            initial: false
            if @is_empty() or @model.get('input_query') == @search_results.query
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
            'typeahead:selected': 'autosuggest_show_details'
            # Important! The following ensures the click
            # will only cause the intended typeahead selection.
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click .typeahead-suggestion.fulltext': 'execute_query'
            'click .action-button.search-button': 'search'

        search: (e) ->
            e.stopPropagation()
            unless @is_empty()
                @execute_query()

        is_empty: () ->
            query = @model.get 'input_query'
            if query? and query.length > 0
                return false
            return true
        onRender: () ->
            @enable_typeahead('input.form-control[type=search]')
            @set_typeahead_width()
            $(window).resize => @set_typeahead_width()
        set_typeahead_width: ->
            windowWidth = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
            if windowWidth < app_settings.mobile_ui_breakpoint
                width = $('#navigation-header').width()
                @$el.find('.tt-dropdown-menu').css 'width': width
            else
                @$el.find('.tt-dropdown-menu').css 'width': 'auto'
        enable_typeahead: (selector) ->
            @$search_el = @$el.find selector
            service_dataset =
                name: 'service'
                source: search.servicemap_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
            event_dataset =
                name: 'event'
                source: search.linkedevents_engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx
            address_dataset =
                source: search.geocoder_engine.ttAdapter(),
                displayKey: (c) -> c.name
                templates:
                    suggestion: (ctx) ->
                        ctx.object_type = 'address'
                        jade.template 'typeahead-suggestion', ctx

            # A hack needed to ensure the header is always rendered.
            full_dataset =
                name: 'header'
                # Source has to return non-empty list
                source: (q, c) -> c([{query: q, object_type: 'query'}])
                displayKey: (s) -> s.query
                name: 'full'
                templates:
                    suggestion: (s) -> jade.template 'typeahead-fulltext', s

            @$search_el.typeahead null, [full_dataset, address_dataset, service_dataset, event_dataset]

            # On enter: was there a selection from the autosuggestions
            # or did the user hit enter without having selected a
            # suggestion?
            selected = false
            @$search_el.on 'typeahead:selected', (ev) =>
                selected = true
            @$search_el.on 'input', (ev) =>
                query = @get_query()
                @model.set 'input_query', query,
                    initial: false,
                    keep_open: true
                @search_results.trigger 'hide'

            @$search_el.keyup (ev) =>
                # Handle enter
                if ev.keyCode != 13
                    selected = false
                    return
                else if selected
                    # Skip autosuggestion selection with keyboard
                    selected = false
                    return
                @execute_query()
        get_query: () ->
            return $.trim @$search_el.val()
        execute_query: () ->
            @$search_el.typeahead 'close'
            app.commands.execute 'search', @model.get 'input_query'
        autosuggest_show_details: (ev, data, _) ->
            @$search_el.typeahead 'val', ''
            @model.set 'input_query', null
            app.commands.execute 'clearSearchResults'
            $('.search-container input').val('')
            # Remove focus from the search box to hide keyboards on touch devices.
            $('.search-container input').blur()
            model = null
            object_type = data.object_type
            switch object_type
                when 'unit'
                    model = new models.Unit(data)
                    app.commands.execute 'setUnit', model
                    app.commands.execute 'selectUnit', model
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
