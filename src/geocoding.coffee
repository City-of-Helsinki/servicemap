define [
    'app/base',
    'app/p13n',
    'app/settings',
    'app/jade',
    'app/models',
    'typeahead.bundle',
    'backbone'
],
(
    sm,
    p13n,
    settings,
    jade,
    models,
    _typeahead,
    Backbone
) ->

    GeocoderSourceBackend: class GeocoderSourceBackend
        constructor: (@options) ->
            _.extend @, Backbone.Events
            @street = undefined
            geocoderStreetEngine = @_createGeocoderStreetEngine p13n.getLanguage()
            @geocoderStreetSource = geocoderStreetEngine.ttAdapter()
        setOptions: (@options) ->
            @options.inputView.on 'typeahead:selected', _.bind(@typeaheadSelected, @)

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
                        results = parsedResponse.results
                        if results.length == 1
                            @setStreet results[0]
                        results
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
                unless data instanceof models.Position
                    @setStreet(data).done =>
                        _.delay (=>
                            @options.inputView.val (@options.inputView.val() + ' ')
                            @options.inputView.trigger 'input'
                        ), 50
            else
                @setStreet null
            if objectType == 'address'
                if data instanceof models.Position
                    console.log data
                    app.commands.execute 'selectPosition', data

        streetSelected: ->
            unless @street?
                return
            _.defer =>
                streetName = p13n.getTranslatedAttr @street.name
                @options.inputView.typeahead('val', '')
                @options.inputView.typeahead('val', streetName + ' ')
                @options.inputView.trigger 'input'

        setStreet: (street) =>
            sm.withDeferred (deferred) =>
                unless street?
                    @street = undefined
                    deferred.resolve()
                    return
                if street.id == @street?.id
                    deferred.resolve()
                    return
                @street = street
                @street.translatedName = (
                    @street.name[p13n.getLanguage()] or @street.name.fi
                ).toLowerCase()
                @street.addresses = new models.AddressList()
                @street.addresses.comparator = (x) =>
                    parseInt x.get('number')
                @street.addressesFetched = false
                @street.addresses.fetch
                    data:
                        street: @street.id
                        page_size: 200
                    success: =>
                        @street.addressesFetched = true
                        deferred.resolve()

        addressSource: (query, callback) =>
            re = new RegExp "^\\s*#{@street.translatedName}(\\s+\\d.*)?", 'i'
            matches = query.match re
            if matches?
                [q, numberPart] = matches
                # TODO: automatically make this search on focus
                unless numberPart?
                    numberPart = ''
                numberPart = numberPart.replace /\s+/g, ''
                done = =>
                    unless @street?
                        callback []
                    filtered = @street.addresses
                        .filter (a) =>
                            a.humanNumber().indexOf(numberPart) == 0
                    results = filtered.slice(0, 2)
                    last = _(filtered).last()
                    unless last in results
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
                else
                    c.name[p13n.getLanguage()]
            source: @getSource()
            templates:
                suggestion: (c) =>
                    if c instanceof models.Position
                        c.set 'street', @street
                        c.address = c.humanAddress()
                    c.object_type = 'address'
                    jade.template 'typeahead-suggestion', c

