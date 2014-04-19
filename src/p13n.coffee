# Personalization support code

define ['underscore', 'i18next'], (_, i18n) ->
    LOCALSTORAGE_KEY = 'servicemap_p13n'
    CURRENT_VERSION = 1
    SUPPORTED_LANGUAGES = ['fi', 'en', 'sv']

    # When adding a new personalization attribute, you must fill in a
    # sensible default.
    DEFAULTS =
        language: 'fi'

    class ServiceMapPersonalization
        constructor: ->
            @attributes = _.clone DEFAULTS
            # FIXME: Autodetect language? Browser capabilities?
            @fetch()

            i18n.init
                lng: @get_language()
                resGetPath: sm_settings.static_path + 'locales/__lng__.json'
                fallbackLng: SUPPORTED_LANGUAGES[0]
            i18n.setLng @get_language()
            # debugging: make i18n available from JS console
            window.i18n_debug = i18n

        set: (attr, val) ->
            if not attr of @attributes
                throw "attempting to set invalid attribute: #{attr}"
            @attributes[attr] = val
            @save()

        fetch: ->
            if not localStorage
                return

            str = localStorage.getItem LOCALSTORAGE_KEY
            if not str
                return
            attrs = JSON.parse str
            # Only pick the attributes that we currently support.
            attrs = _.pick(attrs, _.keys @attributes)
            @attributes = _.extend @attributes, attrs

        save: ->
            if not localStorage
                return

            data = _.extend @attributes, version: CURRENT_VERSION
            str = JSON.stringify data
            localStorage.setItem LOCALSTORAGE_KEY, str

        get_language: ->
            return @attributes.language

        get_translated_attr: (attr) ->
            if not attr
                return attr

            if not attr instanceof Object
                console.log "translated attribute didn't get a translation object", attr
                return attr

            # Try primary choice first, fallback to whatever's available.
            languages = [@get_language()].concat SUPPORTED_LANGUAGES
            for lang in languages
                if lang of attr
                    return attr[lang]

            console.log "no supported languages found", attr
            return null

        set_language: (new_lang) ->
            if not new_lang of SUPPORTED_LANGUAGES
                throw "#{new_lang} is not supported"
            @set 'language', new_lang

    # Make it a globally accessible variable for convenience
    window.p18n = new ServiceMapPersonalization
    return window.p18n
