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
        # events:
        #     'click .language': 'selectLanguage'
        languageSubdomain:
            fi: 'palvelukartta'
            sv: 'servicekarta'
            en: 'servicemap'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.getSupportedLanguages()
            @refreshCollection()
            @listenTo p13n, 'url', =>
                @render()
        selectLanguage: (ev) ->
            l = $(ev.currentTarget).data('language')
            @p13n.setLanguage(l)
            window.location.reload()
        _replaceUrl: (withWhat) ->
            href = window.location.href
            if href.match /^http[s]?:\/\/[^.]+\.hel\..*/
                return href.replace /\/\/[^.]+./, "//#{withWhat}."
            else
                return href
        serializeData: ->
            data = super()
            for i, val of data.items
                val.link = @_replaceUrl @languageSubdomain[val.code]
            data
        refreshCollection: ->
            selected = @p13n.getLanguage()
            languageModels = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter languageModels, (l) -> !l.get('selected')
