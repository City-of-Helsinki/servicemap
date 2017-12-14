define ->
    # https://github.com/HSLdevcom/digitransit-ui/blob/master/app/util/route-compare.js
    routeCompare: (patternA, patternB) ->
        routea = patternA.route
        routeb = patternB.route
        partsA = (routea.shortName or '').match(/^[A-Za-z]?(0*)([0-9]*)/)
        partsB = (routeb.shortName or '').match(/^[A-Za-z]?(0*)([0-9]*)/)
        if partsA[1].length != partsB[1].length
            if partsA[1].length + partsA[2].length == 0
                return -1
                # A is the one with no numbers at all, wins leading zero
            else if partsB[1].length + partsB[2].length == 0
                return 1
                # B is the one with no numbers at all, wins leading zero
            return partsB[1].length - (partsA[1].length)
        # more leading zeros wins
        numberA = parseInt(partsA[2] or '0', 10)
        numberB = parseInt(partsB[2] or '0', 10)
        numberA - numberB or (routea.shortName or '').localeCompare(routeb.shortName or '') or (routea.longName or '').localeCompare(routeb.longName or '')
