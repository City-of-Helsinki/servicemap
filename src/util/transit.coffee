define ->
    SUBWAY_STATION_SERVICE_ID: 437
    SUBWAY_STATION_STOP_UNIT_DISTANCE: 150

    typeToName:
        0: 'tram'
        1: 'subway'
        2: 'rail'
        3: 'bus'
        4: 'ferry'
        109: 'rail'

    vehicleTypes:
        BUS: 3
        FERRY: 4
        RAIL: 2
        SUBWAY: 1
        TRAM: 0

    # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/util/route-compare.js
    routeCompare: (patternA, patternB) ->
        routeA = patternA.route
        routeB = patternB.route
        partsA = (routeA.shortName or '').match(/^[A-Za-z]?(0*)([0-9]*)/)
        partsB = (routeB.shortName or '').match(/^[A-Za-z]?(0*)([0-9]*)/)

        if partsA[1].length != partsB[1].length
            if partsA[1].length + partsA[2].length == 0
                # A is the one with no numbers at all, wins leading zero
                return -1
            else if partsB[1].length + partsB[2].length == 0
                # B is the one with no numbers at all, wins leading zero
                return 1
            # more leading zeros wins
            return partsB[1].length - (partsA[1].length)

        numberA = parseInt(partsA[2] or '0', 10)
        numberB = parseInt(partsB[2] or '0', 10)

        numberA - numberB or
            (routeA.shortName or '').localeCompare(routeB.shortName or '') or
            (routeA.longName or '').localeCompare(routeB.longName or '')
