define (require) ->
    # This module is a temporary solution to fetch pre-generated
    # accessibility sentences before we can access all the data allowing
    # them to be generated on demand.
    _        = require 'underscore'
    Raven    = require 'raven'
    Backbone = require 'backbone'

    models   = require 'cs!app/models'

    BASE_URL = 'https://api.hel.fi/palvelukarttaws/rest/v3/unit/'
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

    fetchAccessibilitySentences = (unit, callback) ->
        args =
            dataType: 'jsonp'
            url: BASE_URL + unit.id
            jsonpCallback: 'jcbAsc'
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
                    Raven.captureMessage(
                        'Timeout reached for unit accessibility sentences',
                        context)
                else if exception
                    Raven.captureException exception, context
                else
                    Raven.captureMessage(
                        'Unidentified error in unit accessibility sentences',
                        context)
                callback error: true
        @xhr = $.ajax args

    fetch:
        fetchAccessibilitySentences
