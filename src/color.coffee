define ->

    class ColorMatcher
        @serviceColors:
            # Housing and environment
            50000: [77,139,0]

            # Administration and economy
            50001: [192,79,220]

            # Culture and leisure
            50002: [252,173,0]

            # Maps, information services and communication
            50003: [154,0,0]

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

            # The following are not root services
            # in the simplified service tree
            # Legal protection and democracy
            #26244: [192,79,220]
            # Planning, real estate and construction
            #25142: [40,40,40]
            # Tourism and events
            #25954: [252,172,0]
            # Entrepreneurship, work and taxation
            #26098: [192,79,220]
            # Sports and physical exercise
            #28128: [252,173,0]

        constructor: (@selectedServices) ->
        @rgb: (r, g, b) ->
            return "rgb(#{r}, #{g}, #{b})"
        @rgba: (r, g, b, a) ->
            return "rgba(#{r}, #{g}, #{b}, #{a})"
        serviceColor: (service) ->
            @serviceRootIdColor service.get('root')
        serviceRootIdColor: (id) ->
            [r, g, b] = @constructor.serviceColors[id]
            @constructor.rgb(r, g, b)
        unitColor: (unit) ->
            roots = unit.get('root_services')
            if @selectedServices?
                rootService = _.find roots, (rid) =>
                    @selectedServices.find (s) ->
                        s.get('root') == rid
            unless rootService?
                rootService = roots[0]
            [r, g, b] = @constructor.serviceColors[rootService]
            @constructor.rgb(r, g, b)

    return ColorMatcher
