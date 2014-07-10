define 'app/search', ['typeahead.bundle', 'app/p13n', 'app/settings'], (ta, p13n, settings) ->
    lang = p13n.get_language()
    servicemap_engine = new Bloodhound
        name: 'suggestions'
        remote:
            url: app_settings.service_map_backend + "/search/?language=#{lang}&page_size=4&input=%QUERY"
            ajax: settings.applyAjaxDefaults {}
            filter: (parsedResponse) ->
                parsedResponse.results
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace
    linkedevents_engine = new Bloodhound
        name: 'events_suggestions'
        remote:
            url: app_settings.linkedevents_backend + "/search/?language=#{lang}&page_size=4&input=%QUERY"
            ajax: settings.applyAjaxDefaults {}
            filter: (parsedResponse) ->
                parsedResponse.results
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace

    servicemap_engine.initialize()
    linkedevents_engine.initialize()

    return {
        linkedevents_engine: linkedevents_engine
        servicemap_engine: servicemap_engine
    }
