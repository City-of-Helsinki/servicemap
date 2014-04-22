define 'app/search', ['typeahead.bundle'], (ta) ->

    engine = new Bloodhound
        name: 'suggestions'
        remote:
            url: sm_settings.backend_url + '/search?input=%QUERY'
            filter: (parsedResponse) ->
                parsedResponse.results
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name.fi
        queryTokenizer: Bloodhound.tokenizers.whitespace

    promise = engine.initialize()
    promise.done -> true
    promise.fail -> false

    return engine: engine
