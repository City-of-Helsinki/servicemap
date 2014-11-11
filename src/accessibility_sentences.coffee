define ['underscore', 'backbone', 'app/models'], (_, Backbone, models) ->

    # This module is a temporary solution to fetch pre-generated
    # accessibility sentences before we can access all the data allowing
    # them to be generated on demand.

    BASE_URL = 'http://www.hel.fi/palvelukarttaws/rest/v3/unit/'
    LANGUAGES = ['fi', 'sv', 'en']

    _build_translated_object = (data, base) ->
        _.object _.map(LANGUAGES, (lang) ->
            [lang, data["#{base}_#{lang}"]])

    current_id = 0
    ids = {}
    _generate_id = (content) ->
        unless content of ids
            ids[content] = current_id
            current_id += 1
        ids[content]

    _parse = (data) ->
        sentences = { }
        groups = { }
        _.each data.accessibility_sentences, (sentence) ->
            group = _build_translated_object sentence, 'sentence_group'
            key = _generate_id group.fi
            groups[key] = group
            unless key of sentences
                sentences[key] = []
            sentences[key].push _build_translated_object(sentence, 'sentence')
        groups:
            groups
        sentences:
            sentences

    fetch_accessibility_sentences = (unit, callback) ->
        args =
            dataType: 'jsonp'
            url: BASE_URL + unit.id
            success: (data) ->
                console.log data
                callback _parse(data)
        @xhr = $.ajax args

    fetch:
        fetch_accessibility_sentences
