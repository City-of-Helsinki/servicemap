# Personalization support code
define (require) ->
    module   = require 'module'
    _        = require 'underscore'
    Backbone = require 'backbone'
    i18n     = require 'i18next'
    moment   = require 'moment'

    # Moment languages. Imported variables
    # unused, but imports must not be removed.
    _fi      = require 'moment/fi'
    _sv      = require 'moment/sv'
    _gb      = require 'moment/en-gb'

    models   = require 'cs!app/models'
    dataviz  = require 'cs!app/data-visualization'

    makeMomentLang = (lang) ->
        if lang == 'en'
            return 'en-gb'
        return lang

    SUPPORTED_LANGUAGES = appSettings.supported_languages
    LOCALSTORAGE_KEY = 'servicemap_p13n'
    CURRENT_VERSION = 2
    LANGUAGE_NAMES =
        fi: 'suomi'
        sv: 'svenska'
        en: 'English'
    HEATMAP_LAYERS = dataviz.getHeatmapLayers()

    statistics_layers = dataviz.getStatisticsLayers().map (layer) -> "current.#{layer}"
    forecast_layers = dataviz.getForecastsLayers().map (layer) -> "forecast.#{layer}"
    STATISTICS_LAYERS = [statistics_layers..., forecast_layers...]

    ACCESSIBILITY_GROUPS = {
        senses: ['hearing_aid', 'visually_impaired', 'colour_blind'],
        mobility: ['wheelchair', 'reduced_mobility', 'rollator', 'stroller'],
    }

    ALLOWED_VALUES =
        accessibility:
            mobility: [null, 'wheelchair', 'reduced_mobility', 'rollator', 'stroller']
        transport: ['by_foot', 'bicycle', 'public_transport', 'car']
        transport_detailed_choices:
            public: ['bus', 'tram', 'metro', 'train', 'ferry']
            bicycle: ['bicycle_parked', 'bicycle_with']
        language: SUPPORTED_LANGUAGES
        map_background_layer: ['servicemap', 'ortographic', 'guidemap', 'accessible_map']
        heatmap_layer: [null, HEATMAP_LAYERS...]
        statistics_layer: [null, STATISTICS_LAYERS...]
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
        language: appSettings.language
        first_visit: true
        skip_tour: false
        hide_tour: false
        location_requested: false
        map_background_layer: 'servicemap'
        accessibility:
            hearing_aid: false
            visually_impaired: false
            colour_blind: false
            mobility: null
        city:
            helsinki: false
            espoo: false
            vantaa: false
            kauniainen: false
        transport:
            by_foot: false
            bicycle: false
            public_transport: true
            car: false
        transport_detailed_choices:
            public:
                bus: true
                tram: true
                metro: true
                train: true
                ferry: true
            bicycle:
                bicycle_parked: true
                bicycle_with: false
        heatmap_layer: null
        statistics_layer: null

    migrateCityFromV1ToV2 = (source) ->
        city = source.city
        source.city = _.clone DEFAULTS.city
        if not city of source.city
            return
        source.city[city] = true

    deepExtend = (target, source, allowedValues) ->
        for prop of target
            if prop not of source
                continue
            if prop == 'city' and (typeof source.city == 'string' or source.city == null)
                migrateCityFromV1ToV2 source

            sourceIsObject = !!source[prop] and typeof source[prop] == 'object'
            targetIsObject = !!target[prop] and typeof target[prop] == 'object'
            if targetIsObject != sourceIsObject
                console.error "Value mismatch for #{prop}: #{typeof source[prop]} vs. #{typeof target[prop]}"
                continue

            if targetIsObject
                deepExtend target[prop], source[prop], allowedValues[prop] or {}
                continue
            if prop of allowedValues
                if target[prop] not in allowedValues[prop]
                    console.error "Invalid value for #{prop}: #{target[prop]}"
                    continue
            target[prop] = source[prop]

    class ServiceMapPersonalization
        constructor: ->
            _.extend @, Backbone.Events

            @attributes = _.clone DEFAULTS
            # FIXME: Autodetect language? Browser capabilities?
            if module.config().localStorageEnabled == false
                @localStorageEnabled = false
            else
                @localStorageEnabled = @testLocalStorageEnabled()
            @_fetch()

            @deferred = i18n.init
                lng: @getLanguage()
                resGetPath: appSettings.static_path + 'locales/__lng__.json'
                fallbackLng: []

            #TODO: This should be moved to a more appropriate place (and made nicer)
            i18n.addPostProcessor "fixFinnishStreetNames", (value, key, options) ->
                REPLACEMENTS = "_allatiivi_": [
                    [/katu$/, "kadulle"],
                    [/polku$/, "polulle"],
                    [/ranta$/, "rannalle"],
                    [/ramppia$/, "rampille"],
                    [/$/, "lle"]
                ],
                "_partitiivi_": [
                    [/tie$/, "tietä"],
                    [/Kehä I/, "Kehä I:tä"]
                    [/Kehä III/, "Kehä III:a"]
                    [/ä$/, "ää"],
                    [/$/, "a"]
                ]
                for grammaticalCase, rules of REPLACEMENTS
                    if value.indexOf(grammaticalCase) > -1
                        for replacement in rules
                            if options.street.match(replacement[0])
                                options.street = options.street.replace(replacement[0], replacement[1]);
                                return value.replace(grammaticalCase, options.street)

            moment.locale makeMomentLang(@getLanguage())
            # debugging: make i18n available from JS console
            window.i18nDebug = i18n

        testLocalStorageEnabled: () =>
            val = '_test'
            try
                localStorage.setItem val, val
                localStorage.removeItem val
                return true
            catch e
                return false

        _handleLocation: (pos, positionObject) =>
            if pos.coords.accuracy > 10000
                @trigger 'position_error'
                return
            unless positionObject?
                positionObject = new models.CoordinatePosition isDetected: true
            cb = =>
                coords = pos['coords']
                positionObject.set 'location',
                    coordinates: [coords.longitude, coords.latitude]
                positionObject.set 'accuracy', pos.coords.accuracy
                @lastPosition = positionObject
                @trigger 'position', positionObject
                if not @get 'location_requested'
                    @set 'location_requested', true
            if appSettings.user_location_delayed
                setTimeout cb, 3000
            else
                cb()


        setVisited: ->
            @_setValue ['first_visit'], false

        getLastPosition: ->
            return @lastPosition

        getLocationRequested: ->
            return @get 'location_requested'

        _setValue: (path, val) ->
            pathStr = path.join '.'
            vars = @attributes
            allowed = ALLOWED_VALUES
            dirs = path.slice 0
            propName = dirs.pop()
            for name in dirs
                if name not of vars
                    throw new Error "Attempting to set invalid variable name: #{pathStr}"
                vars = vars[name]
                if not allowed
                    continue
                if name not of allowed
                    allowed = null
                    continue
                allowed = allowed[name]

            if allowed and propName of allowed
                if val not in allowed[propName]
                    throw new Error "Invalid value for #{pathStr}: #{val}"
            else if typeof val != 'boolean'
                throw new Error "Invalid value for #{pathStr}: #{val} (should be boolean)"

            oldVal = vars[propName]
            if oldVal == val
                return
            vars[propName] = val

            # save changes
            @_save()
            # notify listeners
            @trigger 'change', path, val
            if path[0] == 'accessibility'
                @trigger 'accessibility-change'
            if path[0] == 'city'
                @trigger 'city-change'
            val

        toggleMobility: (val) ->
            oldVal = @getAccessibilityMode 'mobility'
            if val == oldVal
                @_setValue ['accessibility', 'mobility'], null
            else
                @_setValue ['accessibility', 'mobility'], val
        toggleAccessibilityMode: (modeName) ->
            oldVal = @getAccessibilityMode modeName
            @_setValue ['accessibility', modeName], !oldVal
        setAccessibilityMode: (modeName, val) ->
            @_setValue ['accessibility', modeName], val
        getAccessibilityMode: (modeName) ->
            accVars = @get 'accessibility'
            if not modeName of accVars
                throw new Error "Attempting to get invalid accessibility mode: #{modeName}"
            return accVars[modeName]
        toggleCity: (val) ->
            oldVal = @get 'city'
            @_setValue ['city', val], !oldVal[val]
        setCities: (cities) ->
            oldVal = @get 'city'
            for key of oldVal
                enabled = (key in cities) or false
                @_setValue ['city', key], enabled
            oldVal

        getAllAccessibilityProfileIds: ->
            rawIds = _.invert PROFILE_IDS
            ids = {}
            for rid, name of rawIds
                suffixes = switch
                    when _.contains(["1", "2", "3"], rid) then ['A', 'B', 'C']
                    when _.contains(["4", "6"], rid) then ['A']
                    when "5" == rid then ['A', 'B']
                for s in suffixes
                    ids[rid + s] = name
            ids

        getAccessibilityProfileIds: (filterTransit) ->
            # filterTransit: if true, only return profiles which
            # affect transit routing.
            ids = {}
            accVars = @get 'accessibility'
            transport = @get 'transport'
            mobility = accVars['mobility']
            key = PROFILE_IDS[mobility]
            if key
                if key in [1, 2, 3, 5]
                    key += if transport.car then 'B' else 'A'
                else
                    key += 'A'
                ids[key] = mobility
            disabilities = ['visually_impaired']
            unless filterTransit
                disabilities.push 'hearing_aid'
            for disability in disabilities
                val = @getAccessibilityMode disability
                if val
                    key = PROFILE_IDS[disability]
                    if disability == 'visually_impaired'
                        key += if transport.car then 'B' else 'A'
                    else
                        key += 'A'
                    ids[key] = disability
            ids

        hasAccessibilityIssues: ->
            ids = @getAccessibilityProfileIds()
            _.size(ids) > 0

        setTransport: (modeName, val) ->
            modes = @get 'transport'
            if val
                if modeName == 'by_foot'
                    for m of modes
                        modes[m] = false
                else if modeName in ['car', 'bicycle']
                    for m of modes
                        if m == 'public_transport'
                            continue
                        modes[m] = false
                else if modeName == 'public_transport'
                    modes.by_foot = false
            else
                otherActive = false
                for m of modes
                    if m == modeName
                        continue
                    if modes[m]
                        otherActive = true
                        break
                if not otherActive
                    return

            @_setValue ['transport', modeName], val

        getTransport: (modeName) ->
            modes = @get 'transport'
            if not modeName of modes
                throw new Error "Attempting to get invalid transport mode: #{modeName}"
            return modes[modeName]

        toggleTransport: (modeName) ->
            oldVal = @getTransport modeName
            @setTransport modeName, !oldVal

        toggleTransportDetails: (group, modeName) ->
            oldVal = @get('transport_detailed_choices')[group][modeName]
            if !oldVal
                if modeName == 'bicycle_parked'
                    @get('transport_detailed_choices')[group].bicycle_with = false
                if modeName == 'bicycle_with'
                    @get('transport_detailed_choices')[group].bicycle_parked = false
            @_setValue ['transport_detailed_choices', group, modeName], !oldVal

        requestLocation: (positionModel, successCallback, failureCallback) ->
            if appSettings.user_location_override
                override = appSettings.user_location_override
                coords =
                    latitude: override[0]
                    longitude: override[1]
                    accuracy: 10
                @_handleLocation coords: coords
                return

            if 'geolocation' not of navigator
                return
            posOpts =
                enableHighAccuracy: false
                timeout: 30000
            navigator.geolocation.getCurrentPosition ((pos) =>
                @_handleLocation(pos, positionModel)
                successCallback?()
            ),  () =>
                failureCallback?()
                @trigger 'position_error'
                @set 'location_requested', false
            , posOpts

        set: (attr, val) ->
            if not attr of @attributes
                throw new Error "attempting to set invalid attribute: #{attr}"
            @attributes[attr] = val
            @trigger 'change', attr, val
            @_save()

        get: (attr) ->
            if not attr of @attributes
                return undefined
            return @attributes[attr]

        _verifyValidState: ->
            transportModesCount = _.filter(@get('transport'), _.identity).length
            if transportModesCount == 0
                @setTransport 'public_transport', true

        _fetch: ->
            if not @localStorageEnabled
                return

            str = localStorage.getItem LOCALSTORAGE_KEY
            if not str
                return

            storedAttrs = JSON.parse str
            deepExtend @attributes, storedAttrs, ALLOWED_VALUES
            @_verifyValidState()

        _save: ->
            if not @localStorageEnabled
                return

            data = _.extend @attributes, version: CURRENT_VERSION
            str = JSON.stringify data
            localStorage.setItem LOCALSTORAGE_KEY, str

        getProfileElement: (name) ->
            icon: "icon-icon-#{name.replace '_', '-'}"
            text: i18n.t("personalisation.#{name}")

        getProfileElements: (profiles) ->
            _.map(profiles, @getProfileElement)

        getLanguage: ->
            return appSettings.language

        getTranslatedAttr: (attr) ->
            if not attr
                return attr

            if not attr instanceof Object
                console.error "translated attribute didn't get a translation object", attr
                return attr

            # Try primary choice first, fallback to whatever's available.
            languages = [@getLanguage()].concat SUPPORTED_LANGUAGES
            for lang in languages
                if lang of attr
                    return attr[lang]

            console.error "no supported languages found", attr
            return null

        getCity: ->
            cities = @get 'city'
            for city, value of cities
                if value
                    return city
        getCities: ->
            cities = @get 'city'
            ret = []
            for city, value of cities
                if value
                    ret.push city
            return ret

        getSupportedLanguages: ->
            _.map SUPPORTED_LANGUAGES, (l) ->
                code: l
                name: LANGUAGE_NAMES[l]

        getHumanizedDate: (time) ->
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
                    format = switch @getLanguage()
                        when 'fi' then 'Do MMMM[ta]'
                        when 'en' then 'D MMMM'
                        when 'sv' then 'D MMMM'
                s = m.format format
            return s

        setMapBackgroundLayer: (layerName) ->
            @_setValue ['map_background_layer'], layerName

        getMapBackgroundLayers: ->
            a =_(ALLOWED_VALUES.map_background_layer)
                .chain()
                .union ['accessible_map']
                .map (layerName) =>
                    name: layerName,
                    selected: @get('map_background_layer') == layerName
                .value()
        toggleDataLayer: (layer, layerName) ->
            if layerName == 'null'
                layerName = null
            @_setValue [layer], layerName

        getHeatmapLayers: ->
            layers = []
            ALLOWED_VALUES.heatmap_layer.map (layerName) =>
                layers.push {name: layerName}
                return
            layers

        getStatisticsLayers: ->
            layers = []
            ALLOWED_VALUES.statistics_layer.map (layerName) =>
                layers.push {name: layerName}
                return
            layers

    # Make it a globally accessible variable for convenience
    window.p13n = new ServiceMapPersonalization
    return window.p13n
