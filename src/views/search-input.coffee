define (require) ->
    typeahead = require 'typeahead.bundle'

    i18n      = require 'i18next'
    models    = require 'cs!app/models'
    jade      = require 'cs!app/jade'
    search    = require 'cs!app/search'
    geocoding = require 'cs!app/geocoding'
    base      = require 'cs!app/views/base'

    class SearchInputView extends base.SMItemView
        classname: 'search-input-element'
        template: 'navigation-search'
        initialize: ({@model, @searchResults}) ->
            @listenTo @searchResults, 'ready', @adaptToQuery
        adaptToQuery: (model, value, opts) ->
            $container = @$el.find('.action-button')
            $icon = $container.find('span')
            if @isEmpty() or @getInputText() == @searchResults.query
                $icon.removeClass 'icon-icon-forward-bold'
                $icon.addClass 'icon-icon-close'
                $container.removeClass 'search-button'
                $container.addClass 'close-button'
                $icon.attr 'aria-label', i18n.t("sidebar.close_search")
            else
                $icon.addClass 'icon-icon-forward-bold'
                $icon.removeClass 'icon-icon-close'
                $container.removeClass 'close-button'
                $container.addClass 'search-button'
                $icon.attr 'aria-label', i18n.t("sidebar.search")
        events:
            'typeahead:selected': 'autosuggestShowDetails'
            # Important! The following ensures the click
            # will only cause the intended typeahead selection,
            # and doesn't affect the header state
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click input': '_onInputClicked'
            'click .typeahead-suggestion.fulltext': 'executeQuery'
            'click .action-button.search-button': 'search'
            'submit .input-container': 'search'
            'input input': 'adaptToQuery'
            'focus input': '_onInputClicked'

        search: (e) ->
            e.stopPropagation()
            e.preventDefault()
            if @isEmpty()
                return
            @$searchEl.typeahead 'close'
            @executeQuery()

        isEmpty: () ->
            query = @getInputText()
            if query? and query.length > 0
                return false
            return true
        _onInputClicked: (ev) ->
            @trigger 'open'
            ev.stopPropagation()
        _getSearchEl: ->
            if @$searchEl?
                @$searchEl
            else
                @$searchEl = @$el.find 'input.form-control[type=search]'
        setInputText: (query) ->
            $el = @_getSearchEl()
            if $el.length
                $el.typeahead 'val', query
        getInputText: ->
            $el = @_getSearchEl()
            if $el.length
                $el.typeahead 'val'
            else
                null
        onDomRefresh: () ->
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
                    suggestion: (ctx) ->
                        ctx.object_type = 'event'
                        jade.template 'typeahead-suggestion', ctx

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
                    app.request 'selectPosition', data
        getQuery: () ->
            return $.trim @$searchEl.val()
        executeQuery: () ->
            @geocoderBackend.street = null
            @$searchEl.typeahead 'close'
            app.request 'search', @getInputText(), {}
        autosuggestShowDetails: (ev, data, _) ->
            # Remove focus from the search box to hide keyboards on touch devices.
            # TODO: re-enable in a compatible way
            #$('.search-container input').blur()
            model = null
            objectType = data.object_type or data['@type']
            if objectType == 'address'
                return
            if objectType == 'Event/LinkedEvent'
                objectType = 'event'
            @$searchEl.typeahead 'val', ''
            app.request 'clearSearchResults', navigate: false
            $('.search-container input').val('')
            @$searchEl.typeahead 'close'
            switch objectType
                when 'unit'
                    model = new models.Unit(data)
                    app.request 'selectUnit', model, replace: true
                when 'service'
                    # TODO take municipalityids into account
                    service = new models.Service(data)
                    app.request 'addService', service, {}
                when 'event'
                    app.request 'selectEvent',
                        new models.Event(data)
                when 'query'
                    app.request 'search', data.query, {}
