define [
    'moment',
    'underscore',
    'raven',
    'backbone',
    'i18next',
    'app/base',
    'app/settings',
    'app/spinner',
    'app/alphabet',
    'app/accessibility'
], (
    moment,
    _,
    Raven,
    Backbone,
    i18n,
    {mixOf: mixOf, pad: pad, withDeferred: withDeferred}
    settings,
    SMSpinner,
    alphabet,
    accessibility
) ->

    BACKEND_BASE = appSettings.service_map_backend
    LINKEDEVENTS_BASE = appSettings.linkedevents_backend
    OPEN311_BASE = appSettings.open311_backend
    OPEN311_WRITE_BASE = appSettings.open311_write_backend + '/'

    # TODO: remove and handle in geocoder
    MUNICIPALITIES =
        49: 'espoo'
        91: 'helsinki'
        92: 'vantaa'
        235: 'kauniainen'
    MUNICIPALITY_IDS = _.invert MUNICIPALITIES

    Backbone.ajax = (request) ->
        request = settings.applyAjaxDefaults request
        return Backbone.$.ajax.call Backbone.$, request

    class FilterableCollection extends Backbone.Collection
        initialize: (options) ->
            @filters = {}
        setFilter: (key, val) ->
            if not val
                if key of @filters
                    delete @filters[key]
            else
                @filters[key] = val
            @
        clearFilters: ->
            @filters = {}
        fetch: (options) ->
            data = _.clone @filters
            if options.data?
                data = _.extend data, options.data
            options.data = data
            super options

    class RESTFrameworkCollection extends FilterableCollection
        parse: (resp, options) ->
            # Transform Django REST Framework response into PageableCollection
            # compatible structure.
            @fetchState =
                count: resp.count
                next: resp.next
                previous: resp.previous
            super resp.results, options

    class WrappedModel extends Backbone.Model
        initialize: (model) ->
            super()
            @wrap model
        wrap: (model) ->
            @set 'value', model or null
        value: ->
            @get 'value'
        isEmpty: ->
            return not @has 'value'
        isSet: ->
            return not @isEmpty()

    class GeoModel
        getLatLng: ->
            if @latLng?
                @latLng
            coords = @get('location')?.coordinates
            if coords?
                @latLng = L.GeoJSON.coordsToLatLng coords
            else
                null

        getDistanceToLastPosition: ->
            position = p13n.getLastPosition()
            if position?
                latLng = @getLatLng()
                if latLng?
                    position.getLatLng().distanceTo latLng
                else
                    Number.MAX_VALUE

    class SMModel extends Backbone.Model
        # FIXME/THINKME: Should we take care of translation only in
        # the view level? Probably.
        getText: (attr) ->
            val = @get attr
            if attr in @translatedAttrs
                return p13n.getTranslatedAttr val
            return val
        toJSON: (options) ->
            data = super()
            if not @translatedAttrs
                return data
            for attr in @translatedAttrs
                if attr not of data
                    continue
                data[attr] = p13n.getTranslatedAttr data[attr]
            return data

        url: ->
            ret = super
            if ret.substr -1 != '/'
                ret = ret + '/'
            return ret

        urlRoot: ->
            return "#{BACKEND_BASE}/#{@resourceName}/"

    class SMCollection extends RESTFrameworkCollection
        initialize: (models, options) ->
            @filters = {}
            @currentPage = 1
            if options?
                @pageSize = options.pageSize || 25
                if options.setComparator
                    @setDefaultComparator()
            super options

        url: ->
            obj = new @model
            return "#{BACKEND_BASE}/#{obj.resourceName}/"

        isSet: ->
            return not @isEmpty()

        setFilter: (key, val) ->
            if not val
                if key of @filters
                    delete @filters[key]
            else
                @filters[key] = val
            return @

        clearFilters: ->
            @filters = {}

        fetchNext: (options) ->
            if @fetchState? and not @fetchState.next
                return false

            @currentPage++
            defaults = {reset: false, remove: false}
            if options?
                options = _.extend options, defaults
            else
                options = defaults
            @fetch options

        fetch: (options) ->
            if options?
                options = _.clone options
            else
                options = {}

            unless options.data?
                options.data = {}
            options.data.page = @currentPage
            options.data.page_size = @pageSize

            if options.spinnerOptions?.container
                spinner = new SMSpinner(options.spinnerOptions)
                spinner.start()

                success = options.success
                error = options.error

                options.success = (collection, response, options) ->
                    spinner.stop()
                    success?(collection, response, options)

                options.error = (collection, response, options) ->
                    spinner.stop()
                    error?(collection, response, options)

            delete options.spinnerOptions

            super options

        fetchFields: (start, end, fields) ->
            # Fetches more model details for a specified range
            # in the collection.
            if not fields
                return $.Deferred().resolve().promise()
            filtered = _(@slice(start, end)).filter (m) =>
                for field in fields
                    if m.get(field) == undefined
                        return true
                return false
            idsToFetch = _.pluck filtered, 'id'
            unless idsToFetch.length
                return $.Deferred().resolve().promise()
            @fetch
                remove: false
                data:
                    page_size: idsToFetch.length
                    id: idsToFetch.join ','
                    include: fields.join ','

        getComparatorKeys: -> ['default', 'alphabetic', 'alphabetic_reverse']
        getComparator: (key, direction) =>
            switch key
                when 'alphabetic'
                    alphabet.makeComparator direction
                when 'alphabetic_reverse'
                    alphabet.makeComparator -1
                when 'distance'
                    (x) => x.getDistanceToLastPosition()
                when 'distance_precalculated'
                    (x) => x.get 'distance'
                when 'default'
                    (x) => -x.get 'score'
                when 'accessibility'
                    (x) => x.getShortcomingCount()
                else
                    null
        comparatorWrapper: (fn) =>
            unless fn
                return fn
            if fn.length == 2
                (a, b) =>
                    fn a.getComparisonKey(), b.getComparisonKey()
            else
                fn

        setDefaultComparator: ->
            @setComparator @getComparatorKeys()[0]
        setComparator: (key, direction) ->
            index = @getComparatorKeys().indexOf(key)
            if index != -1
                @currentComparator = index
                @currentComparatorKey = key
                @comparator = @comparatorWrapper @getComparator(key, direction)
        cycleComparator: ->
            unless @currentComparator?
                @currentComparator = 0
            @currentComparator += 1
            @currentComparator %= @getComparatorKeys().length
            @reSort @getComparatorKeys()[@currentComparator]
        reSort: (key, direction) ->
            @setComparator key, direction
            if @comparator?
                @sort()
            key
        getComparatorKey: ->
            @currentComparatorKey

        hasReducedPriority: ->
            false

    class Unit extends mixOf SMModel, GeoModel
        resourceName: 'unit'
        translatedAttrs: ['name', 'description', 'street_address']

        initialize: (options) ->
            super options
            @eventList = new EventList()
            @feedbackList = new FeedbackList()

        getEvents: (filters, options) ->
            if not filters?
                filters = {}
            if 'start' not of filters
                filters.start = 'today'
            if 'sort' not of filters
                filters.sort = 'start_time'
            filters.location = "tprek:#{@get 'id'}"
            @eventList.filters = filters
            if not options?
                options =
                    reset: true
            else if not options.reset
                options.reset = true
            @eventList.fetch options

        getFeedback: (options) ->
            @feedbackList.setFilter 'service_object_id', @id
            #@feedbackList.setFilter 'updated_after', '2015-05-20'
            options = options or {}
            _.extend options, reset: true
            @feedbackList.fetch options

        isDetectedLocation: ->
            false
        isPending: ->
            false

        otpSerializeLocation: (opts) ->
            if opts.forceCoordinates
                coords = @get('location').coordinates
                "#{coords[1]},#{coords[0]}"
            else
                "poi:tprek:#{@get 'id'}"

        getSpecifierText: ->
            specifierText = ''
            unless @get('services')?
                return specifierText
            level = null
            for service in @get 'services'
                if not level or service.level < level
                    specifierText = service.name[p13n.getLanguage()]
                    level = service.level
            return specifierText

        getComparisonKey: ->
            p13n.getTranslatedAttr @get('name')

        toJSON: (options) ->
            data = super()
            openingHours = _.filter @get('connections'), (c) ->
                c.section == 'opening_hours' and p13n.getLanguage() of c.name
            lang = p13n.getLanguage()
            if openingHours.length > 0
                data.opening_hours = _(openingHours)
                    .chain()
                    .sortBy 'type'
                    .map (hours) =>
                        content: hours.name[lang]
                        url: hours.www_url?[lang]
                    .value()

            highlights = _.filter @get('connections'), (c) ->
                (c.section in ['miscellaneous', 'topical']) and p13n.getLanguage() of c.name
            data.highlights = _.sortBy highlights, (c) -> c.type

            links = _.filter @get('connections'), (c) ->
                c.section == 'links' and p13n.getLanguage() of c.name
            data.links = _.sortBy links, (c) -> c.type
            data

        hasBboxFilter: ->
            @collection?.filters?.bbox?

        hasAccessibilityData: ->
            # TODO: re-enable these services when data ready
            fn = (x)-> x.id in [33467, 33399]
            blacklistHits = _(@get('services')).filter(fn).length
            @get('accessibility_properties')?.length and blacklistHits == 0

        getTranslatedShortcomings: ->
            profiles = p13n.getAccessibilityProfileIds()
            {status: status, results: shortcomings} = accessibility.getTranslatedShortcomings profiles, @

        getShortcomingCount: ->
            unless @hasAccessibilityData()
                return Number.MAX_VALUE
            shortcomings = @getTranslatedShortcomings()
            @shortcomingCount = 0
            for __, group of shortcomings.results
                @shortcomingCount += _.values(group).length
            @shortcomingCount

    class UnitList extends SMCollection
        model: Unit
        comparator: null
        initialize: (models, opts) ->
            super models, opts
            @forcedPriority = opts?.forcedPriority
        getComparatorKeys: ->
            keys = []
            if p13n.hasAccessibilityIssues() then keys.push 'accessibility'
            if @overrideComparatorKeys?
                return _(@overrideComparatorKeys).union keys
            _(keys).union ['default', 'distance', 'alphabetic', 'alphabetic_reverse']
        hasReducedPriority: ->
            ret = if @forcedPriority
                false
            else
                @filters?.bbox?
            return ret

    class Department extends SMModel
        resourceName: 'department'
        translatedAttrs: ['name']

    class DepartmentList extends SMCollection
        model: Department

    class Organization extends SMModel
        resourceName: 'organization'
        translatedAttrs: ['name']

    class OrganizationList extends SMCollection
        model: Organization

    class AdministrativeDivision extends SMModel
        resourceName: 'administrative_division'
        translatedAttrs: ['name']
        getEmergencyCareUnit: ->
            if @get('type') == 'emergency_care_district'
                switch @get('ocd_id')
                    when 'ocd-division/country:fi/kunta:helsinki/päivystysalue:haartmanin_päivystysalue'
                        return 11828 # Haartman
                    when 'ocd-division/country:fi/kunta:helsinki/päivystysalue:marian_päivystysalue'
                        return 4060 # Malmi
                    # The next ID anticipates a probable change in the division name
                    when 'ocd-division/country:fi/kunta:helsinki/päivystysalue:malmin_päivystysalue'
                        return 4060 # Malmi
            null
    class AdministrativeDivisionList extends SMCollection
        model: AdministrativeDivision

    class AdministrativeDivisionType extends SMModel
        resourceName: 'administrative_division_type'

    class AdministrativeDivisionTypeList extends SMCollection
        model: AdministrativeDivision

    class Service extends SMModel
        resourceName: 'service'
        translatedAttrs: ['name']
        initialize: ->
            @set 'units', new models.UnitList null, setComparator: true
            units = @get 'units'
            units.overrideComparatorKeys = ['alphabetic', 'alphabetic_reverse', 'distance']
            units.setDefaultComparator()
        getSpecifierText: ->
            specifierText = ''
            unless @get('ancestors')?
                return specifierText
            for ancestor, index in @get 'ancestors'
                if index > 0
                    specifierText += ' • '
                specifierText += ancestor.name[p13n.getLanguage()]
            return specifierText
        getComparisonKey: ->
            p13n.getTranslatedAttr @get('name')

    class Street extends SMModel
        resourceName: 'street'
        translatedAttrs: ['name']
        humanAddress: ->
            name = p13n.getTranslatedAttr @get('name')
            "#{name}, #{@getMunicipalityName()}"
        getMunicipalityName: ->
            i18n.t "municipality.#{@get('municipality')}"

    class StreetList extends SMCollection
        model: Street

    class Position extends mixOf SMModel, GeoModel
        resourceName: 'address'
        origin: -> 'clicked'
        isPending: ->
            false
        urlRoot: ->
            "#{BACKEND_BASE}/#{@resourceName}"
        parse: (response, options) ->
            data = super response, options
            street = data.street
            if street
                data.street = new Street street
            data
        isDetectedLocation: ->
            false
        isReverseGeocoded: ->
            @get('street')?
        getSpecifierText: ->
            @getMunicipalityName()
        slugifyAddress: ->
            SEPARATOR = '-'
            street = @get 'street'
            municipality = street.getMunicipalityName().toLowerCase()

            slug = []
            add = (x) -> slug.push x

            streetName = street.getText 'name'
                .toLowerCase()
                # escape dashes by doubling them
                .replace(SEPARATOR, SEPARATOR + SEPARATOR)
                .replace(/\ +/g, SEPARATOR)
            add @get('number')

            numberEnd = @get 'number_end'
            letter = @get 'letter'
            if numberEnd then add "#{SEPARATOR}#{numberEnd}"
            if letter then slug[slug.length-1] += SEPARATOR + letter
            @slug = "#{municipality}/#{streetName}/#{slug.join(SEPARATOR)}"
            @slug
        humanAddress: (opts)->
            street = @get 'street'
            result = []
            if street?
                result.push p13n.getTranslatedAttr(street.get('name'))
                result.push @humanNumber()
                if not opts?.exclude?.municipality and street.get('municipality')
                    last = result.pop()
                    last += ','
                    result.push last
                    result.push @getMunicipalityName()
                result.join(' ')
            else
                null
        getMunicipalityName: ->
            @get('street').getMunicipalityName()
        getComparisonKey: (model) ->
            street = @get 'street'
            result = []
            if street?
                result.push i18n.t("municipality.#{street.get('municipality')}")
                [number, letter] = [@get('number'), @get('letter')]
                result.push pad(number)
                result.push letter
            result.join ''

        _humanNumber: ->
            result = []
            if @get 'number'
                result.push @get 'number'
            if @get 'number_end'
                result.push '-'
                result.push @get 'number_end'
            if @get 'letter'
                result.push @get 'letter'
            result
        humanNumber: ->
            @_humanNumber().join ''
        otpSerializeLocation: (opts) ->
            coords = @get('location').coordinates
            "#{coords[1]},#{coords[0]}"

    class AddressList extends SMCollection
        model: Position

    class CoordinatePosition extends Position
        origin: ->
            if @isDetectedLocation()
                'detected'
            else
                super()
        initialize: (attrs) ->
            @isDetected = if attrs?.isDetected? then attrs.isDetected else false
        isDetectedLocation: ->
            @isDetected
        reverseGeocode: ->
            withDeferred (deferred) =>
                unless @get('street')?
                    posList = models.PositionList.fromPosition @
                    @listenTo posList, 'sync', =>
                        bestMatch = posList.first()
                        if bestMatch.get('distance') > 500
                            bestMatch.set 'name', i18n.t 'map.unknown_address'
                        @set bestMatch.toJSON()
                        deferred.resolve()
                        @trigger 'reverse-geocode'
        isPending: ->
            !@get('location')?

    class AddressPosition extends Position
        origin: -> 'address'
        initialize: (data) ->
            unless data?
                return
            super
            @set 'location',
                coordinates: data.location.coordinates
                type: 'Point'
        isDetectedLocation: ->
            false

    class PositionList extends SMCollection
        resourceName: 'address'
        @fromPosition: (position) ->
            instance = new PositionList()
            name = position.get('street')?.get('name')
            location = position.get 'location'
            instance.model = Position
            if location and not name
                instance.fetch data:
                    lat: location.coordinates[1]
                    lon: location.coordinates[0]
            else if name and not location
                lang = p13n.getLanguage()
                unless lang in appSettings.street_address_languages
                    lang = appSettings.street_address_languages[0]
                data =
                    language: lang
                    number: position.get('number')
                    street: name
                street = position.get('street')
                if street.has 'municipality_name'
                    data.municipality_name = street.get 'municipality_name'
                else if street.has 'municipality'
                    data.municipality = street.get 'municipality'
                instance.fetch data: data
            instance

        @fromSlug: (municipality, streetName, numberPart) ->
            SEPARATOR = '-'
            numberParts = numberPart.split SEPARATOR
            number = numberParts[0]
            number = numberPart.replace /-.*$/, ''
            fn = (memo, value) =>
                if value == ''
                    # Double (escaped) dashes result in an empty
                    # element.
                    "#{memo}#{SEPARATOR}"
                else if memo.charAt(memo.length - 1) == SEPARATOR
                    "#{memo}#{value}"
                else
                    "#{memo} #{value}"
            street = new Street
                name: _.reduce streetName.split(SEPARATOR), fn
                municipality_name: municipality
            @fromPosition new Position
                street: street
                number: number
        getComparatorKeys: -> ['alphabetic']
        # parse: (resp, options) ->
        #     super resp.results, options
        url: ->
            "#{BACKEND_BASE}/#{@resourceName}/"

    class RoutingParameters extends Backbone.Model
        initialize: (attributes)->
            @set 'endpoints', attributes?.endpoints.slice(0) or [null, null]
            @set 'origin_index', attributes?.origin_index or 0
            @set 'time_mode', attributes?.time_mode or 'depart'
            @pendingPosition = new CoordinatePosition isDetected: false, preventPopup: true
            @listenTo @, 'change:time_mode', -> @triggerComplete()

        swapEndpoints: (opts)->
            @set 'origin_index', @_getDestinationIndex()
            unless opts?.silent
                @trigger 'change'
                @triggerComplete()
        setOrigin: (object, opts) ->
            index = @get 'origin_index'
            @get('endpoints')[index] = object
            @trigger 'change'
            unless opts?.silent
                @triggerComplete()
        setDestination: (object) ->
            @get('endpoints')[@_getDestinationIndex()] = object
            @trigger 'change'
            @triggerComplete()
        getDestination: ->
            @get('endpoints')[@_getDestinationIndex()]
        getOrigin: ->
            @get('endpoints')[@_getOriginIndex()]
        getEndpointName: (object) ->
            if not object?
                return ''
            else if object.isDetectedLocation()
                if object.isPending()
                    return i18n.t('transit.location_pending')
                else
                    return i18n.t('transit.current_location')
            else if object instanceof CoordinatePosition
                return i18n.t('transit.user_picked_location')
            else if object instanceof Unit
                return object.getText('name')
            else if object instanceof Position
                return object.humanAddress()
        getEndpointLocking: (object) ->
            return object instanceof models.Unit
        isComplete: ->
            for endpoint in @get 'endpoints'
                unless endpoint? then return false
                if endpoint instanceof Position
                    if endpoint.isPending()
                        return false
            true
        ensureUnitDestination: ->
            if @getOrigin() instanceof Unit
                @swapEndpoints
                    silent: true
        triggerComplete: ->
            if @isComplete()
                @trigger 'complete'
        setTime: (time, opts) ->
            datetime = @getDatetime()
            mt = moment(time)
            m = moment(datetime)
            m.hours mt.hours()
            m.minutes mt.minutes()
            datetime = m.toDate()
            @set 'time', datetime, opts
            @triggerComplete()
        setDate: (date, opts) ->
            datetime = @getDatetime()
            md = moment(date)
            datetime.setDate md.date()
            datetime.setMonth md.month()
            datetime.setYear md.year()
            @set 'time', datetime, opts
            @triggerComplete()
        setTimeAndDate: (date) ->
            @setTime(date)
            @setDate(date)
        setDefaultDatetime: ->
            @set 'time', @getDefaultDatetime()
            @triggerComplete()
        clearTime: ->
            @set 'time', null
        getDefaultDatetime: (currentDatetime) ->
            time = moment new Date()
            mode = @get 'time_mode'
            if mode == 'depart'
                return time.toDate()
            time.add 60, 'minutes'
            minutes = time.minutes()
            # Round upwards to nearest 10 min
            time.minutes (minutes - minutes % 10 + 10)
            time.toDate()
        getDatetime: ->
            time = @get('time')
            unless time?
                time = @getDefaultDatetime()
            time

        isTimeSet: ->
            @get('time')?
        setTimeMode: (timeMode) ->
            @set 'time_mode', timeMode
            @triggerComplete()

        _getOriginIndex: ->
            @get 'origin_index'
        _getDestinationIndex: ->
            (@_getOriginIndex() + 1) % 2

    class Language extends Backbone.Model

    class LanguageList extends Backbone.Collection
        model: Language

    class ServiceList extends SMCollection
        model: Service
        initialize: ->
            super
            @chosenService = null
        expand: (id, spinnerOptions = {}) ->
            if not id
                @chosenService = null
                @fetch
                    data:
                        level: 0
                    spinnerOptions: spinnerOptions
                    success: =>
                        @trigger 'finished'
            else
                @chosenService = new Service(id: id)
                @chosenService.fetch
                    success: =>
                        @fetch
                            data:
                                parent: id
                            spinnerOptions: spinnerOptions
                            success: =>
                                @trigger 'finished'

    class SearchList extends SMCollection
        model: (attrs, options) ->
                typeToModel =
                    service: Service
                    unit: Unit
                    address: Position

                type = attrs.object_type
                if type of typeToModel
                    return new typeToModel[type](attrs, options)
                else
                    Raven.captureException(
                        new Error("Unknown search result type '#{type}', #{attrs.object_type}")
                    )
                    return new Backbone.Model(attrs, options)

        search: (query, options) ->
            @currentPage = 1
            @query = query
            opts = _.extend {}, options
            opts.data =
                q: query
                language: p13n.getLanguage()
                only: 'unit.name,service.name,unit.location,unit.root_services'
                include: 'unit.accessibility_properties,service.ancestors,unit.services'
            city = p13n.get('city')
            if city
                opts.data.municipality = city
            @fetch opts
            opts

        url: ->
            return "#{BACKEND_BASE}/search/"

    class LinkedEventsModel extends SMModel
        urlRoot: ->
            return "#{LINKEDEVENTS_BASE}/#{@resourceName}/"

    class LinkedEventsCollection extends SMCollection
        url: ->
            obj = new @model
            return "#{LINKEDEVENTS_BASE}/#{obj.resourceName}/"

        parse: (resp, options) ->
            @fetchState =
                count: resp.meta.count
                next: resp.meta.next
                previous: resp.meta.previous
            RESTFrameworkCollection.__super__.parse.call @, resp.data, options


    class Event extends LinkedEventsModel
        resourceName: 'event'
        translatedAttrs: ['name', 'info_url', 'description', 'short_description',
                           'location_extra_info']
        toJSON: (options) ->
            data = super()
            data.links = _.filter @get('external_links'), (link) ->
                link.language == p13n.getLanguage()
            data

        getUnit: () ->
            unitId = @get('location')['@id'].match(/^.*tprek%3A(\d+)/)
            unless unitId?
                return null
            return new models.Unit id: unitId[1]


    class EventList extends LinkedEventsCollection
        model: Event

    class Open311Model extends SMModel
        sync: (method, model, options) ->
            _.defaults options, emulateJSON: true, data: extensions: true
            super method, model, options
        resourceNamePlural: ->
            "#{@resourceName}s"
        urlRoot: ->
            return "#{OPEN311_BASE}/#{@resourceNamePlural()}"

    class FeedbackItem extends Open311Model
        resourceName: 'request'
        url: ->
            return "#{@urlRoot()}/#{@id}.json"
        parse: (resp, options) ->
            if resp.length == 1
                return super resp[0], options
            super resp, options

    class FeedbackItemType extends Open311Model
        # incoming feedback

    class FeedbackList extends FilterableCollection
        fetch: (options) ->
            options = options or {}
            _.defaults options,
                emulateJSON: true,
                data: extensions: true
            super options
        model: FeedbackItem
        url: ->
            obj = new @model
            return "#{OPEN311_BASE}/#{obj.resourceNamePlural()}.json"

    class FeedbackMessage extends SMModel
        # outgoing feedback
        # TODO: combine the two?
        initialize: ->
            @set 'can_be_published', true
            @set 'service_request_type', 'OTHER'
            @set 'description', ''

        _serviceCodeFromPersonalisation: (type) ->
            switch type
                when 'hearing_aid' then 128
                when 'visually_impaired' then 126
                when 'wheelchair' then 121
                when 'reduced_mobility' then 123
                when 'rollator' then 124
                when 'stroller' then 125
                else 11
        validate: (attrs, options) ->
            if attrs.description == ''
                description: 'description_required'
            else if attrs.description.trim().length < 10
                @set 'description', attrs.description
                description: 'description_length'
        serialize: ->
            json = _.pick @toJSON(), 'title', 'first_name', 'description',
                'email', 'service_request_type', 'can_be_published'
            viewpoints = @get 'accessibility_viewpoints'
            if viewpoints?.length
                service_code = @_serviceCodeFromPersonalisation viewpoints[0]
            else
                if @get 'accessibility_enabled'
                    service_code = 11
                else
                    service_code = 1363
            json.service_code = service_code
            json.service_object_id = @get('unit').get 'id'
            json.service_object_type = 'http://www.hel.fi/servicemap/v2'
            json
        sync: (method, model, options) ->
            json = @serialize()
            unless @validationError
                if method == 'create'
                    $.post @urlRoot(), @serialize(), => @trigger 'sent'
        urlRoot: -> OPEN311_WRITE_BASE

    exports =
        Unit: Unit
        Service: Service
        UnitList: UnitList
        Department: Department
        DepartmentList: DepartmentList
        Organization: Organization
        OrganizationList: OrganizationList
        ServiceList: ServiceList
        AdministrativeDivision: AdministrativeDivision
        AdministrativeDivisionList: AdministrativeDivisionList
        AdministrativeDivisionType: AdministrativeDivisionType
        AdministrativeDivisionTypeList: AdministrativeDivisionTypeList
        SearchList: SearchList
        Language: Language
        LanguageList: LanguageList
        Event: Event
        WrappedModel: WrappedModel
        EventList: EventList
        RoutingParameters: RoutingParameters
        Position: Position
        CoordinatePosition: CoordinatePosition
        AddressPosition: AddressPosition
        PositionList: PositionList
        AddressList: AddressList
        FeedbackItem: FeedbackItem
        FeedbackList: FeedbackList
        FeedbackMessage: FeedbackMessage
        Street: Street
        StreetList: StreetList

    # Expose models to browser console to aid in debugging
    window.models = exports

    return exports
