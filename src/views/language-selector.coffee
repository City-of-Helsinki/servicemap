define (require) ->
    _            = require 'underscore'

    models       = require 'cs!app/models'
    base         = require 'cs!app/views/base'
    {getLangURL} = require 'cs!app/base'

    class LanguageSelectorView extends base.SMItemView
        template: 'language-selector'
        # events:
        #     'click .language': 'selectLanguage'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.getSupportedLanguages()
            @type = opts.type
            @refreshCollection()
            @listenTo p13n, 'url', =>
                @render()
        serializeData: ->
            data = super()
            data.type = @type
            for i, val of data.items
                val.link = getLangURL val.code
            data
        refreshCollection: ->
            selected = @p13n.getLanguage()
            languageModels = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter languageModels, (l) -> !l.get('selected')
