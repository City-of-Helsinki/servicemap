define 'app/color', () ->

    service_colors =
         # Housing and environment
        25298: [77,139,0]

         # Administration and economy
        26300: [192,79,220]

         # Maps, information services and communication
        25476: [154,0,0]

         # Traffic
        25554: [154,0,0]

         # Culture and leisure
        25622: [252,173,0]

         # Legal protection and democracy
        26244: [192,79,220]

         # Planning, real estate and construction
        25142: [40,40,40]

         # Tourism and events
        25954: [252,172,0]

         # Entrepreneurship, work and taxation
        26098: [192,79,220]

         # Sports and physical exercise
        28128: [252,173,0]

         # Teaching and education
        26412: [0,81,142]

         # Family and social services
        27918: [67,48,64]

         # Child daycare and pre-school education
        27718: [60,210,0]

         # Health care
        25000: [142,139,255]

         # Public safety
        26190: [240,66,0]

    rgb = (r, g, b) ->
        return "rgb(#{r}, #{g}, #{b})"

    rgba = (r, g, b, a) ->
        return "rgba(#{r}, #{g}, #{b}, #{a})"

    service_color = (service) ->
        [r, g, b] = service_colors[service.get('root')]
        return rgb(r, g, b)

    unit_color = (unit, selected_services) ->
        roots = unit.get('root_services')
        root_service = _.find roots, (rid) ->
            selected_services.find (s) ->
                s.get('root') == rid
        unless root_service?
            root_service = roots[0]
        [r, g, b] = service_colors[root_service]
        return rgb(r, g, b)

    return {
        rgb: rgb
        rgba: rgba
        colors: service_colors
        service_color: service_color
        unit_color: unit_color
    }
