define ['underscore', 'backbone', 'backbone-pageable'], (_, Backbone, PageableCollection) ->
    backend_base = sm_settings.backend_url

    class RESTFrameworkCollection extends PageableCollection
        parse: (resp, options) ->
            # Transform Django REST Framework response into PageableCollection
            # compatible structure.
            for obj in resp.results
                if not obj.resource_uri
                    continue
                # Remove trailing slash
                s = obj.resource_uri.replace /\/$/, ''
                obj.id = s.split('/').pop()
            state =
                count: resp.count
                next: resp.next
                previous: resp.previous
            super [state, resp.results], options

    class SMModel extends Backbone.Model
        # FIXME/THINKME: Should we take care of translation only in
        # the view level? Probably.
        get_text: (attr) ->
            val = @get attr
            if attr in @translated_attrs
                return p18n.get_translated_attr val
            return val
        toJSON: (options) ->
            data = super()
            if not @translated_attrs
                return data
            for attr in @translated_attrs
                if attr not of data
                    continue
                data[attr] = p18n.get_translated_attr data[attr]
            return data

        urlRoot: ->
            return "#{backend_base}/#{@resource_name}/"

    class SMCollection extends RESTFrameworkCollection
        url: ->
            obj = new @model
            return "#{backend_base}/#{obj.resource_name}/"

    class Unit extends SMModel
        resource_name: 'unit'
        translated_attrs: ['name', 'description', 'street_address']

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

    class ServiceList extends SMCollection
        model: Service
        initialize: ->
            @chosen_service = null
        expand: (id) ->
            if not id
                @chosen_service = null
                @fetch
                    data:
                        level: 0
            else
                @chosen_service = new Service(id: id)
                @chosen_service.fetch
                    success: =>
                        @fetch
                            data:
                                parent: id

    class SearchList extends SMCollection
        initialize: ->
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
                language: p18n.get_language()
            opts.reset = true
            @fetch opts

        search: (query, options) ->
            opts = _.extend {}, options
            opts.data =
                q: query
                language: p18n.get_language()
            opts.reset = true
            @fetch opts

        url: ->
            return "#{backend_base}/search/"

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

    # Expose models to browser console to aid in debugging
    window.models = exports

    return exports
