define ['underscore', 'backbone', 'backbone-tastypie'], (_, Backbone) ->
    backend_base = sm_settings.backend_url

    class Unit extends Backbone.Model

    class UnitList extends Backbone.Collection
        urlRoot: backend_base + '/unit/'

    class Department extends Backbone.Model

    class DepartmentList extends Backbone.Collection
        urlRoot: backend_base + '/department/'

    class Organization extends Backbone.Model

    class OrganizationList extends Backbone.Collection
        urlRoot: backend_base + '/organization/'

    class AdministrativeDivision extends Backbone.Model

    class AdministrativeDivisionList extends Backbone.Collection
        urlRoot: backend_base + '/administrative_division/'

    class AdministrativeDivisionType extends Backbone.Model

    class AdministrativeDivisionTypeList extends Backbone.Collection
        urlRoot: backend_base + '/administrative_division_type/'

    class Service extends Backbone.Model

    class ServiceList extends Backbone.Collection
        urlRoot: backend_base + '/service/'
        initialize: (@level) ->
            @parent_service = null
        fetch: (options) ->
            options = options or {}
            options.data = options.data or {}
            options.data.level = @level
            Backbone.Collection.prototype.fetch.call(this, options)
        dive: (id) ->
            @parent_service = @find (x) ->
                x.attributes.id == parseInt(id)
            @level++
            @fetch
                data:
                    parent: id
        rise: ->
            # todo: implement
            @level--
            if @level < 0
                @level = 0
            @fetch()

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

    return exports
