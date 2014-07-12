# Personalization support code

SUPPORTED_LANGUAGES = ['fi', 'en', 'sv']

make_moment_lang = (lang) ->
    if lang == 'en'
        return 'en-gb'
    return lang

moment_deps = ("moment/#{make_moment_lang(lang)}" for lang in SUPPORTED_LANGUAGES)
p13n_deps = ['underscore', 'backbone', 'i18next', 'moment'].concat moment_deps

define p13n_deps, (_, Backbone, i18n, moment) ->
    LOCALSTORAGE_KEY = 'servicemap_p13n'
    CURRENT_VERSION = 1
    LANGUAGE_NAMES =
        fi: 'suomi'
#        sv: 'svenska'
        en: 'English'
    FALLBACK_LANGUAGES = ['en', 'fi']

    ACCESSIBILITY_GROUPS = {
        senses: ['hearing_aid', 'visually_impaired', 'colour_blind'],
        mobility: ['wheelchair', 'reduced_mobility', 'rollator', 'stroller'],
    }

    # When adding a new personalization attribute, you must fill in a
    # sensible default.
    DEFAULTS =
        language: 'fi'
        location_requested: false
        accessibility_mode:
            hearing_aid: false
            visually_impaired: false
            colour_blind: false
            wheelchair: false
            reduced_mobility: false
            rollator: false
            stroller: false
        transport:
            by_foot: false
            bicycle: false
            public_transport: true
            car: false
        city: null
        transport: 'public'

    class ServiceMapPersonalization
        constructor: ->
            _.extend @, Backbone.Events

            @attributes = _.clone DEFAULTS
            # FIXME: Autodetect language? Browser capabilities?
            @_fetch()

            @deferred = i18n.init
                lng: @get_language()
                resGetPath: app_settings.static_path + 'locales/__lng__.json'
                fallbackLng: FALLBACK_LANGUAGES

            moment.lang make_moment_lang(@get_language())

            # debugging: make i18n available from JS console
            window.i18n_debug = i18n

        _handle_location: (pos) =>
            @last_position = pos
            @trigger 'position', pos
            if not @get 'location_requested'
                @set 'location_requested', true

        _handle_location_error: (error) =>
            alert error.message
            @set 'location_requested', false

        get_last_position: ->
            return @last_position

        get_location_requested: ->
            return @get 'location_requested'

        _set_accessibility: (mode_name, val) ->
            acc_vars = @get 'accessibility_mode'
            if not mode_name of acc_vars
                throw new Error "Attempting to set invalid accessibility mode: #{mode_name}"
            old_val = acc_vars[mode_name]
            if old_val == val
                return
            acc_vars[mode_name] = val

            for group_name of ACCESSIBILITY_GROUPS
                group = ACCESSIBILITY_GROUPS[group_name]
                if mode_name in group
                    break

            # mobility is mutually exclusive, so clear the other modes in the
            # group.
            if group == 'mobility'
                for other_mode in group
                    if not acc_vars[other_mode]
                        continue
                    acc_vars[other_mode] = false
                    @trigger 'accessibility_change', other_mode, old_val

            # save changes
            @set 'accessibility', acc_vars
            # notify listeners
            @trigger 'accessibility_change', mode_name, val

        set_accessibility_mode: (mode_name) ->
            @_set_accessibility mode_name, true
        clear_accessibility_mode: (mode_name) ->
            @_set_accessibility mode_name, false
        get_accessibility_mode: (mode_name) ->
            acc_vars = @get 'accessibility_mode'
            if not mode_name of acc_vars
                throw new Error "Attempting to get invalid accessibility mode: #{mode_name}"
            return !!acc_vars[mode_name]

        request_location: ->
            if app_settings.user_location_override
                override = app_settings.user_location_override
                coords =
                    latitude: override[0]
                    longitude: override[1]
                    accuracy: 10
                @_handle_location coords: coords
                return

            if 'geolocation' not of navigator
                return
            pos_opts =
                enableHighAccuracy: false
                timeout: 30000
            navigator.geolocation.getCurrentPosition @_handle_location,
                @_handle_location_error, pos_opts

        set: (attr, val) ->
            if not attr of @attributes
                throw "attempting to set invalid attribute: #{attr}"
            @attributes[attr] = val
            @_save()

        get: (attr) ->
            if not attr of @attributes
                return undefined
            return @attributes[attr]

        _fetch: ->
            if not localStorage
                return

            str = localStorage.getItem LOCALSTORAGE_KEY
            if not str
                return
            attrs = JSON.parse str
            # Only pick the attributes that we currently support.
            attrs = _.pick(attrs, _.keys @attributes)
            @attributes = _.extend @attributes, attrs

        _save: ->
            if not localStorage
                return

            data = _.extend @attributes, version: CURRENT_VERSION
            str = JSON.stringify data
            localStorage.setItem LOCALSTORAGE_KEY, str

        get_language: ->
            return @get 'language'

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

        get_supported_languages: ->
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
                s = m.calendar()
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
