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

    exports =
        Unit: Unit
        UnitList: UnitList
        Department: Department
        DepartmentList: DepartmentList
        Organization: Organization
        OrganizationList: OrganizationList

    return exports
