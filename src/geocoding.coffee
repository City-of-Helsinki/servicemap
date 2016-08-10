define (require) ->
    _typeahead = require 'typeahead.bundle'
    Backbone   = require 'backbone'

    sm         = require 'cs!app/base'
    p13n       = require 'cs!app/p13n'
    settings   = require 'cs!app/settings'
    jade       = require 'cs!app/jade'
    models     = require 'cs!app/models'

    monkeyPatchTypeahead = ($element) =>
        typeahead = $element.data 'ttTypeahead'
        proto = Object.getPrototypeOf typeahead
        originalSelect = proto._select
        proto._select = (datum) ->
            @input.setQuery datum.value
            @input.setInputValue datum.value, true
            @_setLanguageDirection()
            @eventBus.trigger 'selected', datum.raw, datum.datasetName
            # REMOVED CODE WHICH CLOSES THE DROPDOWN
        proto.closeCompletely = ->
            @destroy()
            _.defer _.bind(@dropdown.empty, @dropdown)

    GeocoderSourceBackend: class GeocoderSourceBackend
        constructor: (@options) ->
            _.extend @, Backbone.Events
            @street = undefined
            geocoderStreetEngine = @_createGeocoderStreetEngine p13n.getLanguage()
            @geocoderStreetSource = geocoderStreetEngine.ttAdapter()
        setOptions: (@options) ->
            @options.$inputEl.on 'typeahead:selected', _.bind(@typeaheadSelected, @)
            @options.$inputEl.on 'typeahead:autocompleted', _.bind(@typeaheadSelected, @)
            monkeyPatchTypeahead @options.$inputEl

        _createGeocoderStreetEngine: (lang) ->
            e = new Bloodhound
                name: 'street_suggestions'
                remote:
                    url: appSettings.service_map_backend + "/street/?page_size=4"
                    replace: (url, query) =>
                        url += "&input=#{query}"
                        url += "&language=#{if lang != 'sv' then 'fi' else lang}"
                        url
                    ajax: settings.applyAjaxDefaults {}
                    filter: (parsedResponse) =>
                        results = new models.StreetList parsedResponse.results
                        if results.length == 1
                            @setStreet results.first()
                        results.toArray()
                    rateLimitWait: 50
                datumTokenizer: (datum) ->
                    Bloodhound.tokenizers.whitespace datum.name[lang]
                queryTokenizer: (s) =>
                    res = [s]
            e.initialize()
            return e

        typeaheadSelected: (ev, data) ->
            objectType = data.object_type
            if objectType == 'address'
                if data instanceof models.Position
                    @options.$inputEl.typeahead 'close'
                    @options.selectionCallback ev, data
                else
                    @setStreet(data).done =>
                        # To support IE on typeahead < v11, we need to call internal API
                        # because typeahead listens to different events on IE compared to
                        # web browsers.
                        typeaheadInput = @options.$inputEl.data('ttTypeahead').input
                        typeaheadInput.setInputValue @options.$inputEl.val() + ' '
            else
                @setStreet null

        streetSelected: ->
            unless @street?
                return
            _.defer =>
                streetName = p13n.getTranslatedAttr @street.name
                @options.$inputEl.typeahead('val', '')
                @options.$inputEl.typeahead('val', streetName + ' ')
                @options.$inputEl.trigger 'input'

        setStreet: (street) =>
            sm.withDeferred (deferred) =>
                unless street?
                    @street = undefined
                    deferred.resolve()
                    return
                if street.get('id') == @street?.get('id')
                    deferred.resolve()
                    return
                @street = street
                @street.translatedName = (
                    @street.get('name')[p13n.getLanguage()] or @street.get('name').fi
                ).toLowerCase()
                @street.addresses = new models.AddressList [], pageSize: 200
                @street.addresses.comparator = (x) =>
                    parseInt x.get('number')
                @street.addressesFetched = false
                @street.addresses.fetch
                    data:
                        street: @street.get('id')
                    success: =>
                        @street?.addressesFetched = true
                        deferred.resolve()

        addressSource: (query, callback) =>
            # escape parentheses for regexp
            streetName = @street.translatedName
                .replace /([()])/g, '\\$1'
            re = new RegExp "^\\s*#{streetName}(\\s+\\d.*)?", 'i'
            matches = query.match re
            if matches?
                [q, numberPart] = matches
                # TODO: automatically make this search on focus
                unless numberPart?
                    numberPart = ''
                numberPart = numberPart.replace(/\s+/g, '').replace /[^0-9]+/g, ''
                done = =>
                    unless @street?
                        callback []
                        return
                    if @street.addresses.length == 1
                        callback @street.addresses.toArray()
                        return
                    filtered = @street.addresses
                        .filter (a) =>
                            a.humanNumber().indexOf(numberPart) == 0
                    results = filtered.slice(0, 2)
                    last = _(filtered).last()
                    unless last in results
                        if last?
                            results.push last
                    callback results
                if @street.addressesFetched
                    done()
                else
                    @listenToOnce @street.addresses, 'sync', =>
                        done()

        getSource: =>
            (query, cb) =>
                if @street? and @street.translatedName.length <= query.length
                    @addressSource query, cb
                else
                    @geocoderStreetSource query, cb

        getDatasetOptions: =>
            name: 'address'
            displayKey: (c) ->
                if c instanceof models.Position
                    c.humanAddress()
                else if c instanceof models.Street
                    c.getText 'name'
                else
                    c
            source: @getSource()
            templates:
                suggestion: (c) =>
                    if c instanceof models.Position
                        c.set 'street', @street
                    c.address = c.humanAddress()
                    c.object_type = 'address'
                    jade.template 'typeahead-suggestion', c

