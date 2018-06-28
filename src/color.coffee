define (require) ->
    Raven = require 'raven'

    class ColorMatcher
        @serviceNodeColors:
            # Housing and environment
            1400: [77,139,0]

            # Administration and economy
            1401: [192,79,220]

            # Culture and leisure
            1403: [252,173,0]

            # Maps, information services and communication
            1402: [154,0,0]

            # Teaching and education
            1087: [0,81,142]

            # Family and social services
            783: [67,48,64]

            # Child daycare and pre-school education
            1405: [60,210,0]

            # Health care
            986: [142,139,255]

            # Public safety
            1061: [240,66,0]

            # The following are not root serviceNodes
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

        constructor: (@selectedServiceNodes) ->
        @rgb: (r, g, b) ->
            return "rgb(#{r}, #{g}, #{b})"
        @rgba: (r, g, b, a) ->
            return "rgba(#{r}, #{g}, #{b}, #{a})"
        serviceNodeColor: (serviceNode) ->
            @serviceNodeRootIdColor serviceNode.get('root')
        serviceNodeRootIdColor: (id) ->
            [r, g, b] = @constructor.serviceNodeColors[id]
            @constructor.rgb(r, g, b)
        unitColor: (unit) ->
            roots = unit.get('root_service_nodes')
            if roots is null
                Raven.captureMessage(
                    'No roots found for unit ' + unit.id,
                    tags: type: 'helfi_rest_api_v4')
                roots = [1400]
            if @selectedServiceNodes?
                rootServiceNode = _.find roots, (rid) =>
                    @selectedServiceNodes.find (s) ->
                        s.get('root') == rid
            unless rootServiceNode?
                rootServiceNode = roots[0]
            [r, g, b] = @constructor.serviceNodeColors[rootServiceNode]
            @constructor.rgb(r, g, b)

    return ColorMatcher
