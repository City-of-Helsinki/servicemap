# Personalization support code

SUPPORTED_LANGUAGES = ['fi', 'en', 'sv']

make_moment_lang = (lang) ->
    if lang == 'en'
        return 'en-gb'
    return lang

moment_deps = ("moment/#{make_moment_lang(lang)}" for lang in SUPPORTED_LANGUAGES)
p13n_deps = ['underscore', 'i18next', 'moment'].concat moment_deps

define p13n_deps, (_, i18n, moment) ->
    LOCALSTORAGE_KEY = 'servicemap_p13n'
    CURRENT_VERSION = 1
    LANGUAGE_NAMES =
        fi: 'suomi'
#        sv: 'svenska'
        en: 'English'
    FALLBACK_LANGUAGES = ['en', 'fi']

    # When adding a new personalization attribute, you must fill in a
    # sensible default.
    DEFAULTS =
        language: 'fi'

    class ServiceMapPersonalization
        constructor: ->
            @attributes = _.clone DEFAULTS
            # FIXME: Autodetect language? Browser capabilities?
            @fetch()

            @deferred = i18n.init
                lng: @get_language()
                resGetPath: sm_settings.static_path + 'locales/__lng__.json'
                fallbackLng: FALLBACK_LANGUAGES

            moment.lang make_moment_lang(@get_language())

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

        supported_languages: () ->
            _.map SUPPORTED_LANGUAGES, (l) ->
                code: l
                name: LANGUAGE_NAMES[l]

        set_language: (new_lang) ->
            if not new_lang of SUPPORTED_LANGUAGES
                throw "#{new_lang} is not supported"
            @set 'language', new_lang

        get_humanized_date: (time) ->
            m = moment time
            now = moment()
            sod = now.startOf 'day'
            diff = m.diff sod, 'days', true
            if diff < -6 or diff >= 7
                humanize = false
            else
                humanize = true
            if humanize
                s = m.calendar time
                s = s.replace /( (klo|at))* \d{1,2}[:.]\d{1,2}$/, ''
            else
                if now.year() != m.year()
                    format = 'L'
                else
                    format = switch @get_language()
                        when 'fi' then 'Do MMMM[ta]'
                        when 'en' then 'D MMMM'
                        when 'sv' then 'D MMMM'
                s = m.format format
            return s

    # Make it a globally accessible variable for convenience
    window.p13n = new ServiceMapPersonalization
    return window.p13n
