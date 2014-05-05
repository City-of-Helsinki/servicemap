define 'app/color', ['app/models'], (models) ->

    service_colors =
         # Housing and environment
        25298: "rgb(77,139,0)"

         # Administration and economy
        26300: "rgb(192,79,220)"

         # Maps, information services and communication
        25476: "rgb(154,0,0)"

         # Traffic
        25554: "rgb(154,0,0)"

         # Culture and leisure
        25622: "rgb(252,173,0)"

         # Legal protection and democracy
        26244: "rgb(192,79,220)"

         # Planning, real estate and construction
        25142: "rgb(40,40,40)"

         # Tourism and events
        25954: "rgb(252,172,0)"

         # Entrepreneurship, work and taxation
        26098: "rgb(192,79,220)"

         # Sports and physical exercise
        28128: "rgb(252,173,0)"

         # Teaching and education
        26412: "rgb(0,81,142)"

         # Family and social services
        27918: "rgb(67,48,64)"

         # Child daycare and pre-school education
        27718: "rgb(60,210,0)"

         # Health care
        25000: "rgb(142,139,255)"

         # Public safety
        26190: "rgb(240,66,0)"


    service_color = (service) ->
        return service_colors[service.get('root')]

    unit_color = (unit) ->
        return service_colors[unit.get('root_services')[0]]

    return {
        service_color: service_color
        unit_color: unit_color
    }
