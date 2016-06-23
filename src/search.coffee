define [
    'backbone',
    'typeahead.bundle',
    'cs!app/p13n',
    'cs!app/settings'
],
(
    Backbone,
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
                cities = p13n.getCities()
                if cities && cities.length
                    for city in cities
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

    servicemapEngine.initialize()
    linkedeventsEngine.initialize()

    linkedeventsEngine: linkedeventsEngine
    servicemapEngine: servicemapEngine
