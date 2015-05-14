define [
    'backbone',
    'typeahead.bundle',
    'app/p13n',
    'app/settings'
],
(
    Backbone,
    ta,
    p13n,
    settings
) ->

    eventChannel = {}
    _.extend eventChannel, Backbone.Events

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

    geocoderStreetEngine = new Bloodhound
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
                eventChannel.trigger 'response-received', results
                results
            rateLimitWait: 50
        datumTokenizer: (datum) -> Bloodhound.tokenizers.whitespace datum.name[lang]
        queryTokenizer: Bloodhound.tokenizers.whitespace

    _.extend geocoderStreetEngine, Backbone.Events

    servicemapEngine.initialize()
    linkedeventsEngine.initialize()
    geocoderStreetEngine.initialize()

    return {
        linkedeventsEngine: linkedeventsEngine
        servicemapEngine: servicemapEngine
        geocoderStreetEngine: geocoderStreetEngine
        searchEvents: eventChannel
    }
