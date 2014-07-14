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

    ALLOWED_VALUES =
        accessibility:
            mobility: [null, 'wheelchair', 'reduced_mobility', 'rollator', 'stroller']
        transport: ['on_foot', 'bicycle', 'public_transport', 'car']
        language: SUPPORTED_LANGUAGES
        city: [null, 'helsinki', 'espoo', 'vantaa', 'kauniainen']

    PROFILE_IDS =
        'wheelchair': 1
        'reduced_mobility': 2
        'rollator': 3
        'stroller': 4
        'visually_impaired': 5
        'hearing_aid': 6

    # When adding a new personalization attribute, you must fill in a
    # sensible default.
    DEFAULTS =
        language: 'fi'
        location_requested: false
        accessibility:
            hearing_aid: false
            visually_impaired: false
            colour_blind: false
            mobility: null
        city: null
        transport: 'public_transport'

    deep_extend = (target, source, allowed_values) ->
        for prop of target
            if prop not of source
                continue
            source_is_object = !!source[prop] and typeof source[prop] == 'object'
            target_is_object = !!target[prop] and typeof target[prop] == 'object'
            if target_is_object != source_is_object
                console.error "Value mismatch for #{prop}: #{typeof source[prop]} vs. #{typeof target[prop]}"
                continue

            if target_is_object
                deep_extend target[prop], source[prop], allowed_values[prop] or {}
                continue
            if prop of allowed_values
                if target[prop] not in allowed_values[prop]
                    console.error "Invalid value for #{prop}: #{target[prop]}"
                    continue
            target[prop] = source[prop]

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

        _set_value: (path, val) ->
            path_str = path.join '.'
            vars = @attributes
            allowed = ALLOWED_VALUES
            dirs = path.slice 0
            prop_name = dirs.pop()
            for name in dirs
                if name not of vars
                    throw new Error "Attempting to set invalid variable name: #{path_str}"
                vars = vars[name]
                if not allowed
                    continue
                if name not of allowed
                    allowed = null
                    continue
                allowed = allowed[name]

            if allowed and prop_name of allowed
                if val not in allowed[prop_name]
                    throw new Error "Invalid value for #{path_str}: #{val}"
            else if typeof val != 'boolean'
                throw new Error "Invalid value for #{path_str}: #{val} (should be boolean)"

            old_val = vars[prop_name]
            if old_val == val
                return
            vars[prop_name] = val

            # save changes
            @_save()
            # notify listeners
            @trigger 'change', path, val
        toggle_mobility: (val) ->
            old_val = @get_accessibility_mode 'mobility'
            if val == old_val
                @_set_value ['accessibility', 'mobility'], null
            else
                @_set_value ['accessibility', 'mobility'], val
        toggle_accessibility_mode: (mode_name) ->
            old_val = @get_accessibility_mode mode_name
            @_set_value ['accessibility', mode_name], !old_val
        set_accessibility_mode: (mode_name, val) ->
            @_set_value ['accessibility', mode_name], val
        get_accessibility_mode: (mode_name) ->
            acc_vars = @get 'accessibility'
            if not mode_name of acc_vars
                throw new Error "Attempting to get invalid accessibility mode: #{mode_name}"
            return acc_vars[mode_name]
        get_accessibility_profile_ids: () ->
            ids = {}
            acc_vars = @get 'accessibility'
            mobility = acc_vars['mobility']
            key = PROFILE_IDS[mobility]
            if key
                ids[key] = mobility
            for key in ['visually_impaired', 'hearing_aid']
                val = @get_accessibility_mode key
                if val
                    ids[PROFILE_IDS[key]] = key
            ids
        set_transport: (new_val) ->
            @_set_value ['transport'], new_val
        get_transport: ->
            return @get 'transport'

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
                throw new Error "attempting to set invalid attribute: #{attr}"
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

            stored_attrs = JSON.parse str
            deep_extend @attributes, stored_attrs, ALLOWED_VALUES

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
                throw new Error "#{new_lang} is not supported"
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
