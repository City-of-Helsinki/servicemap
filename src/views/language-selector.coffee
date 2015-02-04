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
            'click .language': 'selectLanguage'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.getSupportedLanguages()
            @refreshCollection()
        selectLanguage: (ev) ->
            l = $(ev.currentTarget).data('language')
            @p13n.setLanguage(l)
            window.location.reload()
        refreshCollection: ->
            selected = @p13n.getLanguage()
            languageModels = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter languageModels, (l) -> !l.get('selected')
