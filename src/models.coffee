reqs = ['moment', 'underscore', 'backbone', 'i18next', 'app/settings', 'app/spinner']

define reqs, (moment, _, Backbone, i18n, settings, SMSpinner) ->
    BACKEND_BASE = app_settings.service_map_backend
    LINKEDEVENTS_BASE = app_settings.linkedevents_backend
    GEOCODER_BASE = app_settings.geocoder_url

    Backbone.ajax = (request) ->
        request = settings.applyAjaxDefaults request
        return Backbone.$.ajax.call Backbone.$, request

    class RESTFrameworkCollection extends Backbone.Collection
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

    class SMModel extends Backbone.Model
        # FIXME/THINKME: Should we take care of translation only in
        # the view level? Probably.
        get_text: (attr) ->
            val = @get attr
            if attr in @translated_attrs
                return p13n.get_translated_attr val
            return val
        toJSON: (options) ->
            data = super()
            if not @translated_attrs
                return data
            for attr in @translated_attrs
                if attr not of data
                    continue
                data[attr] = p13n.get_translated_attr data[attr]
            return data

        url: ->
            ret = super
            if ret.substr -1 != '/'
                ret = ret + '/'
            return ret

        urlRoot: ->
            return "#{BACKEND_BASE}/#{@resource_name}/"

    class SMCollection extends RESTFrameworkCollection
        initialize: (options) ->
            @filters = {}
            @currentPage = 1
            if options?
                @pageSize = options.pageSize || 25

        url: ->
            obj = new @model
            return "#{BACKEND_BASE}/#{obj.resource_name}/"

        isSet: ->
            return not @isEmpty()

        setFilter: (key, val) ->
            if not val
                if key of @filters
                    delete @filters[key]
            else
                @filters[key] = val

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

            data = _.clone @filters
            data.page = @currentPage
            data.page_size = @pageSize

            if options.data?
                data = _.extend data, options.data
            options.data = data

            if options.spinner_options?.container
                spinner = new SMSpinner(options.spinner_options)
                spinner.start()

                success = options.success
                error = options.error

                options.success = (collection, response, options) ->
                    spinner.stop()
                    success?(collection, response, options)

                options.error = (collection, response, options) ->
                    spinner.stop()
                    error?(collection, response, options)

            delete options.spinner_options

            super options

    class Unit extends SMModel
        resource_name: 'unit'
        translated_attrs: ['name', 'description', 'street_address']

        initialize: (options) ->
            super options
            @event_list = new EventList()

        get_events: (filters, options) ->
            if not filters?
                filters = {}
            if 'start' not of filters
                filters.start = 'today'
            if 'sort' not of filters
                filters.sort = 'start_time'
            filters.location = "tprek:#{@get 'id'}"
            @event_list.filters = filters
            if not options?
                options =
                    reset: true
            else if not options.reset
                options.reset = true
            @event_list.fetch options

        is_detected_location: ->
            false
        is_pending: ->
            false

        otp_serialize_location: (opts) ->
            if opts.force_coordinates
                coords = @get('location').coordinates
                "#{coords[1]},#{coords[0]}"
            else
                "poi:tprek:#{@get 'id'}"

        get_specifier_text: ->
            specifier_text = ''
            level = null
            for service in @get 'services'
                if not level or service.level < level
                    specifier_text = service.name[p13n.get_language()]
                    level = service.level
            return specifier_text

        toJSON: (options) ->
            data = super()

            opening_hours = _.filter @get('connections'), (c) ->
                c.section == 'opening_hours' and c.type == 0 and p13n.get_language() of c.name
            if opening_hours.length > 0
                data.opening_hours = opening_hours[0].name[p13n.get_language()]

            highlights = _.filter @get('connections'), (c) ->
                c.section == 'miscellaneous' and p13n.get_language() of c.name
            data.highlights = _.sortBy highlights, (c) -> c.type

            links = _.filter @get('connections'), (c) ->
                c.section == 'links' and p13n.get_language() of c.name
            data.links = _.sortBy links, (c) -> c.type
            data

    class UnitList extends SMCollection
        model: Unit

    class Department extends SMModel
        resource_name: 'department'
        translated_attrs: ['name']

    class DepartmentList extends SMCollection
        model: Department

    class Organization extends SMModel
        resource_name: 'organization'
        translated_attrs: ['name']

    class OrganizationList extends SMCollection
        model: Organization

    class AdministrativeDivision extends SMModel
        resource_name: 'administrative_division'
        translated_attrs: ['name']

    class AdministrativeDivisionList extends SMCollection
        model: AdministrativeDivision

    class AdministrativeDivisionType extends SMModel
        resource_name: 'administrative_division_type'

    class AdministrativeDivisionTypeList extends SMCollection
        model: AdministrativeDivision

    class Service extends SMModel
        resource_name: 'service'
        translated_attrs: ['name']

        get_specifier_text: ->
            specifier_text = ''
            for ancestor, index in @get 'ancestors'
                if index > 0
                    specifier_text += ' • '
                specifier_text += ancestor.name[p13n.get_language()]
            return specifier_text

    class Position extends Backbone.Model
        resource_name: 'address'
        origin: -> 'clicked'
        is_pending: ->
            false
        urlRoot: ->
            "#{GEOCODER_BASE}/#{@resource_name}"
        is_detected_location: ->
            false

    class CoordinatePosition extends Position
        origin: ->
            if @is_detected_location()
                'detected'
            else
                super()
        initialize: (attrs) ->
            @is_detected = if attrs?.is_detected? then attrs.is_detected else true
        otp_serialize_location: (opts) ->
            coords = @get('location').coordinates
            "#{coords[1]},#{coords[0]}"
        is_detected_location: ->
            @is_detected
        is_pending: ->
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
        is_detected_location: ->
            false
        otp_serialize_location: (opts) ->
            coords = @get('location')['coordinates']
            coords[1] + "," + coords[0]

    class PositionList extends Backbone.Collection
        resource_name: 'address'
        @from_position: (position) ->
            instance = new PositionList()
            name = position.get 'name'
            location = position.get 'location'
            if location and not name
                instance.model = AddressPosition
                instance.fetch data:
                    lat: location.coordinates[1]
                    lon: location.coordinates[0]
            else if name and not location
                instance.model = CoordinatePosition
                instance.fetch data:
                    name: name
            instance
        parse: (resp, options) ->
            super resp.objects, options
        url: ->
            "#{GEOCODER_BASE}/#{@resource_name}/"

    class RoutingParameters extends Backbone.Model
        initialize: (attributes)->
            @set 'endpoints', attributes?.endpoints.slice(0) or [null, null]
            @set 'origin_index', attributes?.origin_index or 0
            @set 'time_mode', attributes?.time_mode or 'depart'
            @listenTo @, 'change:time_mode', -> @trigger_complete()

        swap_endpoints: (opts)->
            @set 'origin_index', @_get_destination_index()
            unless opts?.silent
                @trigger 'change'
                @trigger_complete()
        set_origin: (object, opts) ->
            index = @get 'origin_index'
            @get('endpoints')[index] = object
            @trigger 'change'
            unless opts?.silent
                @trigger_complete()
        set_destination: (object) ->
            @get('endpoints')[@_get_destination_index()] = object
            @trigger 'change'
            @trigger_complete()
        get_destination: ->
            @get('endpoints')[@_get_destination_index()]
        get_origin: ->
            @get('endpoints')[@_get_origin_index()]
        get_endpoint_name: (object) ->
            if not object?
                return ''
            else if object.is_detected_location()
                if object.is_pending()
                    return i18n.t('transit.location_pending')
                else
                    return i18n.t('transit.current_location')
            else if object instanceof CoordinatePosition
                return i18n.t('transit.user_picked_location')
            else if object instanceof Unit
                return object.get_text('name')
            else if object instanceof AddressPosition
                return object.get('name')
        get_endpoint_locking: (object) ->
            return object instanceof models.Unit
        is_complete: ->
            for endpoint in @get 'endpoints'
                unless endpoint? then return false
                if endpoint instanceof Position
                    if endpoint.is_pending()
                        return false
            true
        ensure_unit_destination: ->
            if @get_origin() instanceof Unit
                @swap_endpoints
                    silent: true
        trigger_complete: ->
            if @is_complete()
                @trigger 'complete'
        set_time: (time, opts) ->
            datetime = @get_datetime()
            mt = moment(time)
            m = moment(datetime)
            m.hours mt.hours()
            m.minutes mt.minutes()
            datetime = m.toDate()
            @set 'time', datetime, opts
            @trigger_complete()
        set_date: (date, opts) ->
            datetime = @get_datetime()
            md = moment(date)
            datetime.setDate md.date()
            datetime.setMonth md.month()
            datetime.setYear md.year()
            @set 'time', datetime, opts
            @trigger_complete()
        set_time_and_date: (date) ->
            @set_time(date)
            @set_date(date)
        set_default_datetime: ->
            @set 'time', @get_default_datetime()
            @trigger_complete()
        clear_time: ->
            @set 'time', null
        get_default_datetime: (current_datetime) ->
            time = moment new Date()
            mode = @get 'time_mode'
            if mode == 'depart'
                return time.toDate()
            time.add 60, 'minutes'
            minutes = time.minutes()
            # Round upwards to nearest 10 min
            time.minutes (minutes - minutes % 10 + 10)
            time.toDate()
        get_datetime: ->
            time = @get('time')
            unless time?
                time = @get_default_datetime()
            time

        is_time_set: ->
            @get('time')?
        set_time_mode: (time_mode) ->
            @set 'time_mode', time_mode
            @trigger_complete()

        _get_origin_index: ->
            @get 'origin_index'
        _get_destination_index: ->
            (@_get_origin_index() + 1) % 2

    class Language extends Backbone.Model

    class LanguageList extends Backbone.Collection
        model: Language

    class ServiceList extends SMCollection
        model: Service
        initialize: ->
            super
            @chosen_service = null
        expand: (id, spinner_options = {}) ->
            if not id
                @chosen_service = null
                @fetch
                    data:
                        level: 0
                    spinner_options: spinner_options
            else
                @chosen_service = new Service(id: id)
                @chosen_service.fetch
                    success: =>
                        @fetch
                            data:
                                parent: id
                            spinner_options: spinner_options

    class SearchList extends SMCollection
        initialize: ->
            super
            @model = (attrs, options) ->
                type_to_model =
                    service: Service
                    unit: Unit

                type = attrs.object_type
                if type of type_to_model
                    return new type_to_model[type](attrs, options)
                else
                    console.log "Unknown search result type '#{type}'"
                    return new Backbone.Model(attrs, options)

        autocomplete: (input, options) ->
            opts = _.extend {}, options
            opts.data =
                input: input
                language: p13n.get_language()
            opts.reset = true
            @fetch opts

        search: (query, options) ->
            @query = query
            opts = _.extend {}, options
            opts.data =
                q: query
                language: p13n.get_language()
            @fetch opts

        url: ->
            return "#{BACKEND_BASE}/search/"


    class LinkedEventsModel extends SMModel
        urlRoot: ->
            return "#{LINKEDEVENTS_BASE}/#{@resource_name}/"

    class LinkedEventsCollection extends SMCollection
        url: ->
            obj = new @model
            return "#{LINKEDEVENTS_BASE}/#{obj.resource_name}/"

        parse: (resp, options) ->
            @fetchState =
                count: resp.meta.count
                next: resp.meta.next
                previous: resp.meta.previous
            RESTFrameworkCollection.__super__.parse.call @, resp.data, options


    class Event extends LinkedEventsModel
        resource_name: 'event'
        translated_attrs: ['name', 'info_url', 'description', 'short_description',
                           'location_extra_info']
        toJSON: (options) ->
            data = super()
            data.links = _.filter @get('external_links'), (link) ->
                link.language == p13n.get_language()
            data

        get_unit: () ->
            unit_id = @get('location')['@id'].match(/^.*tprek%3A(\d+)/)
            unless unit_id?
                return null
            return new models.Unit id: unit_id[1]


    class EventList extends LinkedEventsCollection
        model: Event


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
        CoordinatePosition: CoordinatePosition
        AddressPosition: AddressPosition
        PositionList: PositionList

    # Expose models to browser console to aid in debugging
    window.models = exports

    return exports
