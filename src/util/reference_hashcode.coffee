define (require) ->
    _ = require 'underscore'

    compareNumber = (a, b) -> a - b
    compareNumberArray = (a, b) ->
        i = 0
        while i < a.length
            if i >= b.length
                return 1
            c = compareNumber(a[i], b[i])
            if c != 0 then return c
            i++
        return 0

    hashCode = (s) ->
        hash = 0
        i = undefined
        chr = undefined
        if s.length == 0
            return hash
        i = 0
        while i < s.length
            chr = s.charCodeAt i
            hash = (hash << 5) - hash + chr
            hash |= 0  # Convert to 32bit integer
            i++
        hash

    OR_OPERATOR = '+'
    AND_OPERATOR = '*'

    normalize = (reference) ->
        orOperands = reference.split OR_OPERATOR
        parsed = _.map orOperands, (o) =>
            andOperands = _.map o.split(AND_OPERATOR), (x) => parseInt(x)
            andOperands.sort compareNumber
            return andOperands
        parsed.sort compareNumberArray
        return parsed

    referenceHashCode = (serviceReference) ->
        hashCode JSON.stringify(normalize(serviceReference))

    referenceHashCode
