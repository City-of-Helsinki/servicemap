define ['underscore', 'backbone', 'backbone-tastypie'], (_, Backbone) ->
    backend_base = sm_settings.backend_url

    class Unit extends Backbone.Model

    class UnitList extends Backbone.Collection
        urlRoot: backend_base + '/unit/'

    exports =
        Unit: Unit
        UnitList: UnitList
    return exports
