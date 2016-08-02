define (require) ->
    URI = require 'URI'
    cleanAddress: (address) ->
        SEPARATOR = '-'
        modified = false

        separatorsToConvert = /\++/g
        extraZipCode = /^[0-9]+[ -+]+/
        extraCitySuffix = / kaupunki/

        modified = false
        for key in ['municipality', 'street']
            if address[key].search(separatorsToConvert) > -1
                address[key] = address[key].replace(separatorsToConvert, SEPARATOR)
                modified = true
        if address.municipality.search(extraZipCode) > -1
            address.municipality = address.municipality.replace extraZipCode, ''
            modified = true
        if address.municipality.search(extraCitySuffix) > -1
            address.municipality = address.municipality.replace(/espoon kaupunki/i, 'espoo')
            modified = true
        if modified
            uri = new URI
            segment = _.map ['municipality', 'street', 'numberPart'], (key) -> address[key]
            segment.unshift 'address'
            uri.segmentCoded segment
            return [uri, address]
        return [null, null]
