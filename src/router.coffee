define ['app/views', 'backbone'], (Bacbone) ->

    class ServiceMapRouter extends Backbone.Router
        initialize: (@controller) -> this
        routes:
            "service/:id": (id) -> @controller.open_service(id)

    class ServiceMapController
        constructor: (@models) ->
            @router = new ServiceMapRouter(this)
            Backbone.history.start()
            this
        open_service: (id) ->
            @models.service_list.dive id

    exports =
        ServiceMapRouter: ServiceMapRouter
        ServiceMapController: ServiceMapController
    return exports

