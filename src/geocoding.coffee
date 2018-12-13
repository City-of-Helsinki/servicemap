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
                    url: appSettings.service_map_backend + "/search/?page_size=4&type=address"
                    replace: (url, query) =>
                        url += "&input=#{query}"
                        url += "&language=#{if lang != 'sv' then 'fi' else lang}"
                        url
                    ajax: settings.applyAjaxDefaults {}
                    filter: (parsedResponse) =>
                        results = new models.AddressList parsedResponse.results, {parse: true}
                        results.toArray()
                    rateLimitWait: 50
                datumTokenizer: (datum) ->
                    Bloodhound.tokenizers.whitespace datum.name[lang]
                queryTokenizer: (s) =>
                    res = [s]
            e.initialize()
            return e

        typeaheadSelected: (ev, data) ->
            if data instanceof models.Position
                @options.$inputEl.typeahead 'close'
                @options.selectionCallback ev, data

        getSource: =>
            (query, cb) => @geocoderStreetSource query, cb

        getDatasetOptions: =>
            name: 'address'
            displayKey: (c) ->
                if c instanceof models.Position
                    c.humanAddress()
                else
                    c
            source: @getSource()
            templates:
                suggestion: (c) =>
                    c.address = c.humanAddress()
                    c.object_type = 'address'
                    jade.template 'typeahead-suggestion', c

