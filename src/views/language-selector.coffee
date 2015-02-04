define [
    'underscore',
    'app/models',
    'app/views/base',
], (
    _,
    models,
    base
) ->

    class LanguageSelectorView extends base.SMItemView
        template: 'language-selector'
        events:
            'click .language': 'select_language'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.get_supported_languages()
            @refresh_collection()
        select_language: (ev) ->
            l = $(ev.currentTarget).data('language')
            @p13n.set_language(l)
            window.location.reload()
        refresh_collection: ->
            selected = @p13n.get_language()
            language_models = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter language_models, (l) -> !l.get('selected')
