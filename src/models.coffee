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
        urlRoot: ->
            return "#{backend_base}/#{@resource_name}/"

    class SMCollection extends RESTFrameworkCollection
        url: ->
            obj = new @model
            return "#{backend_base}/#{obj.resource_name}/"

    class Unit extends SMModel
        resource_name: 'unit'

    class UnitList extends SMCollection
        model: Unit

    class Department extends SMModel
        resource_name: 'department'

    class DepartmentList extends SMCollection
        model: Department

    class Organization extends SMModel
        resource_name: 'organization'

    class OrganizationList extends SMCollection
        model: Organization

    class AdministrativeDivision extends SMModel
        resource_name: 'administrative_division'

    class AdministrativeDivisionList extends SMCollection
        model: AdministrativeDivision

    class AdministrativeDivisionType extends SMModel
        resource_name: 'administrative_division_type'

    class AdministrativeDivisionTypeList extends SMCollection
        model: AdministrativeDivision

    class Service extends SMModel
        resource_name: 'service'

    class ServiceList extends SMCollection
        model: Service
        initialize: () ->
            @chosen_service = null
        expand: (id) ->
            if not id
                @chosen_service = null
                @fetch data: level: 0
            else
                collection = this
                @chosen_service = new Service(id: id)
                @chosen_service.fetch
                    success: ->
                        collection.fetch data: parent: id

    exports =
        Unit: Unit
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

    # Expose models to browser console to aid in debugging
    window.models = exports

    return exports
