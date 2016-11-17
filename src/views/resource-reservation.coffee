define (require) ->
    backbone = require 'backbone'
    _ = require 'underscore'
    b = require 'cs!app/views/base'

    class ResourceItemView extends b.SMItemView
        template: 'resource-item'
        tagName: 'li'

    class ResourceReservationCompositeView extends b.SMCompositeView
        className: 'resource-reservation-list'
        template: 'resource-reservation'
        childView: ResourceItemView
        childViewContainer: '#resource-reservation'
        initialize: ({@model}) ->
            @collection = new Backbone.Collection()
            super({@collection, @model})
            @getUnitResources()
        getUnitResources: ->
            unitId = @model.get 'id'
            $.ajax
                dataType: 'json'
                url: "#{appSettings.respa_backend}/resource/?unit=tprek:#{unitId}&page_size=100"
                success: (data) =>
                    if data.results.length < 1
                        return
                    @collection.reset _.map(data.results, ({name, id}) =>
                        new Backbone.Model({name, id}))
                    @trigger 'ready'
                error: (jqXHR, testStatus, errorThrown) ->
