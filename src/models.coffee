define ['underscore', 'backbone', 'backbone-tastypie'], (_, Backbone) ->
    class Unit extends Backbone.Model

    class UnitList extends Backbone.Collection

    exports =
        Unit: Unit
    return exports
