define [
    'typeahead.bundle',
    'app/p13n',
    'app/settings'
],
(
    ta,
    p13n,
    settings
) ->

    lang = p13n.getLanguage()
    servicemapEngine = new Bloodhound
        name: 'suggestions'
        remote:
            url: appSettings.service_map_backend + "/search/?language=#{lang}&page_size=4&input="
            replace: (url, query) =>
                url += query
                city = p13n.get('city')
                if city
                    url += "&municipality=#{city}"
                url
            ajax: settings.applyAjaxDefaults {}
            filter: (parsedResponse) ->
                parsedResponse.results
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace
    linkedeventsEngine = new Bloodhound
        name: 'events_suggestions'
        remote:
            url: appSettings.linkedevents_backend + "/search/?language=#{lang}&page_size=4&input=%QUERY"
            ajax: settings.applyAjaxDefaults {}
            filter: (parsedResponse) ->
                parsedResponse.data
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace

    geocoderEngine = new Bloodhound
        name: 'address_suggestions'
        remote:
            url: appSettings.service_map_backend + "/street/?page_size=4"
            replace: (url, query) =>
                url += "&input=#{query}"
                url += "&language=#{if lang != 'sv' then 'fi' else lang}"
                url
            ajax: settings.applyAjaxDefaults {}
            filter: (parsedResponse) ->
                parsedResponse.results
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace

    servicemapEngine.initialize()
    linkedeventsEngine.initialize()
    geocoderEngine.initialize()

    return {
        linkedeventsEngine: linkedeventsEngine
        servicemapEngine: servicemapEngine
        geocoderEngine: geocoderEngine
    }
