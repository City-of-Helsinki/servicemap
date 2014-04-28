define 'app/color', ['app/models'], (models) ->

    service_colors =
        # tree_id: "color"
        # Housing and environment
        1: "rgb(77,139,0)"
        # Administration and economy
        3: "rgb(192,79,220)"
        # Maps, information services and communication
        5: "rgb(154,0,0)"
        # Traffic
        7: "rgb(154,0,0)"
        # Culture and leisure
        6: "rgb(252,173,0)"
        # Legal protection and democracy
        10: "rgb(192,79,220)"
        # Planning, real estate and construction
        4: "rgb(40,40,40)"
        # Tourism and events
        9: "rgb(252,172,0)"
        # Entrepreneurship, work and taxation
        2: "rgb(192,79,220)"
        # Sports and physical exercise
        8: "rgb(252,173,0)"
        # Teaching and education
        11: "rgb(0,81,142)"
        # Family and social services
        12: "rgb(67,48,64)"
        # Child daycare and pre-school education
        13: "rgb(60,210,0)"
        # Health care
        14: "rgb(142,139,255)"
        # Public safety
        15: "rgb(240,66,0)"

    service_color = (service) ->
        return service_colors[service.attributes.tree_id]

    return service_color
