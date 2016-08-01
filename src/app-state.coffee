define (require) ->
    Backbone                = require 'backbone'
    models                  = require 'cs!app/models'
    transit                 = require 'cs!app/transit'

    class AppState
        constructor: ->
            @setDefaultState()
        setDefaultState: ->
            @services = new models.ServiceList()
            @selectedServices = new models.ServiceList()
            @units = new models.UnitList null, setComparator: true
            @selectedUnits = new models.UnitList()
            @selectedEvents = new models.EventList()
            @searchResults = new models.SearchList [], pageSize: appSettings.page_size
            @searchState = new models.WrappedModel()
            @route = new transit.Route()
            @routingParameters = new models.RoutingParameters()
            @selectedPosition = new models.WrappedModel()
            @selectedDivision = new models.WrappedModel()
            @divisions = new models.AdministrativeDivisionList
            @pendingFeedback = new models.FeedbackMessage()
            @dataLayers = new Backbone.Collection [], model: Backbone.Model
            @informationalMessage = new Backbone.Model()
            @cancelToken = new models.WrappedModel()
        setState: (other) ->
            for key, val of @
                continue if key == 'cancelToken'
                if val? and typeof val == 'object' and typeof other[key].restoreState == 'function'
                    @[key].restoreState other[key]
        clone: ->
            other = new AppState()
            other.setState @
            other
        isEmpty: ->
            @selectedServices.isEmpty() and \
            @selectedUnits.isEmpty() and \
            @selectedEvents.isEmpty() and \
            @searchResults.isEmpty() and \
            @selectedPosition.isEmpty()
