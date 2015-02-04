define [
    'underscore',
    'raven',
    'backbone',
    'app/models'
], (
    _,
    Raven,
    Backbone,
    models
) ->

    # This module is a temporary solution to fetch pre-generated
    # accessibility sentences before we can access all the data allowing
    # them to be generated on demand.

    BASE_URL = 'http://www.hel.fi/palvelukarttaws/rest/v3/unit/'
    LANGUAGES = ['fi', 'sv', 'en']
    TIMEOUT = 10000

    _buildTranslatedObject = (data, base) ->
        _.object _.map(LANGUAGES, (lang) ->
            [lang, data["#{base}_#{lang}"]])

    currentId = 0
    ids = {}
    _generateId = (content) ->
        unless content of ids
            ids[content] = currentId
            currentId += 1
        ids[content]

    _parse = (data) ->
        sentences = { }
        groups = { }
        _.each data.accessibility_sentences, (sentence) ->
            group = _buildTranslatedObject sentence, 'sentence_group'
            key = _generateId group.fi
            groups[key] = group
            unless key of sentences
                sentences[key] = []
            sentences[key].push _buildTranslatedObject(sentence, 'sentence')
        groups:
            groups
        sentences:
            sentences

    jcbAsc = (data) -> null
    window.jcbAsc = jcbAsc

    fetchAccessibilitySentences = (unit, callback) ->
        args =
            dataType: 'jsonp'
            url: BASE_URL + unit.id
            jsonp: false
            jsonpCallback: 'jcbAsc'
            data:
                callback: 'jcbAsc'
            cache: true
            success: (data) ->
                callback _parse(data)
            timeout: TIMEOUT
            error: (jqXHR, errorType, exception) ->
                context = {
                    tags:
                        type: 'helfi_rest_api'
                    extra:
                        error_type: errorType
                        jqXHR: jqXHR
                }

                if errorType == 'timeout'
                    Raven.captureException(
                        new Error("Timeout of #{TIMEOUT}ms reached for #{BASE_URL+unit.id}"),
                        context)
                else
                    Raven.captureException exception, context
                callback error: true
        @xhr = $.ajax args

    fetch:
        fetchAccessibilitySentences
