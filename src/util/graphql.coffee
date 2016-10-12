define ->

    PLAN_QUERY = """
    query(
        $modes: String!,
        $from: InputCoordinates!,
        $to: InputCoordinates!,
        $locale: String!,
        $wheelchair: Boolean!) {

        plan(
            from: $from,
            to: $to,
            locale: $locale,
            wheelchair: $wheelchair,
            modes: $modes
        ) {
            itineraries {
              walkDistance,
              duration,
              legs {
                mode
                startTime
                endTime
                from {
                  lat
                  lon
                  name
                  stop {
                    code
                    name
                  }
                },
                to {
                  lat
                  lon
                  name
                },
                agency {
                  id
                },
                distance
                legGeometry {
                  length
                  points
                }
              }
            }
         }
    }
    """

    planQuery: (variables) ->
        query: PLAN_QUERY
        variables: variables
