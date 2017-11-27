define ->

    STOP_QUERY = """
    query(
        $id: String!
    ) {

      stop(
        id: $id
      ) {
        id
        stoptimesWithoutPatterns {
          scheduledArrival
        }
      }
    }
    """

    STOPS_BY_BOUNDING_BOX_QUERY = """
    query(
        $minLat: Float,
        $minLon: Float,
        $maxLat: Float,
        $maxLon: Float
    ) {

      stopsByBbox(
        minLat: $minLat,
        minLon: $minLon,
        maxLat: $maxLat,
        maxLon: $maxLon
      ) {
        id,
        gtfsId,
        name,
        lat,
        lon,
        code
      }
    }
    """

    PLAN_QUERY = """
    query(
        $modes: String!,
        $from: InputCoordinates!,
        $to: InputCoordinates!,
        $locale: String!,
        $wheelchair: Boolean!,
        $date: String,
        $time: String,
        $arriveBy: Boolean,
        $walkReluctance: Float,
        $walkBoardCost: Int,
        $walkSpeed: Float,
        $minTransferTime: Int
        ) {

        plan(
            from: $from,
            to: $to,
            date: $date,
            time: $time,
            arriveBy: $arriveBy,
            locale: $locale,
            wheelchair: $wheelchair,
            modes: $modes,
            walkReluctance: $walkReluctance,
            walkBoardCost: $walkBoardCost,
            walkSpeed: $walkSpeed,
            minTransferTime: $minTransferTime
        ) {
            to { name }
            from { name }
            itineraries {
              startTime,
              endTime,
              walkDistance,
              duration,
              legs {
                transitLeg
                mode
                trip { tripHeadsign }
                route { longName, shortName }
                intermediateStops { name }
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

    stopQuery: (variables) ->
        query: STOP_QUERY
        variables: variables

    stopsByBoundingBoxQuery: (variables) ->
        query: STOPS_BY_BOUNDING_BOX_QUERY
        variables: variables
