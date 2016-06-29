express = require('express')
_ = require('underscore')
config = require 'config'
http = require 'http'

app = express()

languageMap =
    palvelukartta: 'fi'
    servicekarta: 'sv'
    servicemap: 'en'
languageIdMap = _.invert(languageMap)

extractLanguage = (req, isEmbed) ->
    language = 'fi'
    path = null
    language = 'fi'
    value = req.query.lang
    if not value?
        value = req.query.language
    if value
        switch value
            when 'se'
                language = 'sv'
            when 'sv'
                language = 'sv'
            when 'en'
                language = 'en'
    {
        id: language
        isAlias: false
    }

extractServices = (req) ->
    services = req.query.theme
    if !services
        return null
    services = services.split(' ')
    if services.length < 1
        return null
    services.join ','

extractStreetAddress = (req, municipalityParameter) ->
    addressParts = undefined
    addressString = req.query.address or req.query.addresslocation
    if addressString == undefined
        return null
    addressParts = addressString.split(',')
    if addressParts.length < 1
        return null
    municipality = undefined
    if addressParts.length == 2
        municipality = addressParts[1].trim()
    if not municipality?
        municipality = municipalityParameter
    streetPart = addressParts[0].trim()
    numberIndex = streetPart.search(/\d/)
    street = streetPart.substring(0, numberIndex).trim()
    numberPart = streetPart.substring(numberIndex)

    municipality: municipality?.toLowerCase()
    street: street.toLowerCase().replace(/\s+/g, '+')
    number: numberPart.toLowerCase()

extractMunicipality = (req) ->
    municipality = req.query.city
    if municipality? then return municipality

    region = req.query.region
    if not region then return null

    switch region.toLowerCase()
        when 'c91'
            'helsinki'
        when 'c49'
            'espoo'
        when 'c92'
            'vantaa'
        when 'c235'
            'kauniainen'
        else
            null

extractSpecification = (req) ->
    language = undefined
    specs = {}

    dig = (key) ->
        req.query[key] or null

    specs.originalPath = _.filter req.url.split('/'), (s) -> s.length > 0
    if 'embed' in specs.originalPath
        specs.isEmbed = true
    specs.language = extractLanguage(req, specs.isEmbed)
    if specs.language.isAlias == true
        return specs

    specs.unit = dig('id')
    specs.searchQuery = dig('search')
    specs.radius = dig('distance')
    specs.organization = dig('organization')

    specs.municipality = extractMunicipality(req)
    specs.services = extractServices(req)
    specs.address = extractStreetAddress(req, specs.municipality)
    if specs.address != null
        specs.serviceCategory = dig('service')
    specs

encodeQueryComponent = (value) ->
    encodeURIComponent(value).replace(/%20/g, '+').replace /%2C/g, ','

generateQuery = (specs, resource, originalUrl) ->
    query = ''
    queryParts = []

    addQuery = (key, value) ->
        if value == null or value == undefined
            return
        queryParts.push [
            key
            encodeQueryComponent(value)
        ].join('=')
        return

    addQuery 'q', specs.searchQuery
    addQuery 'municipality', specs.municipality
    addQuery 'service', specs.services
    addQuery 'organization', specs.organization
    if resource = 'address'
        addQuery 'radius', specs.radius

    originalUrl = originalUrl.replace /\/rdr\/?/, ''
    queryParts.push '_rdr=' + encodeURIComponent(originalUrl)
    if queryParts.length == 0
        return ''
    '?' + queryParts.join('&')

getResource = (specs) ->
    if specs.unit or (specs.services and not specs.searchQuery)
        return 'unit'
    else if specs.searchQuery
        return 'search'
    else if specs.address
        return 'address'
    null

generateUrl = (specs, originalUrl) ->
    protocol = 'http://'
    subDomain = languageIdMap[specs.language.id]
    resource = getResource(specs)
    host = [
        subDomain
        'hel'
        'fi'
    ].join('.')
    path = [ host ]
    fragment = ''

    if specs.isEmbed == true
        # TODO: kml versions ?
        path.push 'embed'
    if resource
        path.push resource
    if resource == 'address'
        address = specs.address
        path = path.concat([
            address.municipality
            address.street
            address.number
        ])
        if specs.serviceCategory != null
            fragment = '#!service-details'
    else if resource == 'unit' and specs.unit != null
        path.push specs.unit
    protocol + path.join('/') + generateQuery(specs, resource, originalUrl) + fragment


getMunicipalityFromGeocoder = (address, language, callback) ->
    municipality = address.municipality
    if municipality? and municipality.length
        callback municipality
        return

    timeout = setTimeout (-> callback null), 3000

    url = "#{config.service_map_backend}/address/?language=#{language}&number=#{address.number}&street=#{address.street}&page_size=1"
    request = http.get url, (apiResponse) ->
        if apiResponse.statusCode != 200
            clearTimeout timeout
            callback null
            return
        respData = ''
        apiResponse.on 'data', (data) ->
            respData += data
        apiResponse.on 'end', ->
            addressInfo = JSON.parse respData
            clearTimeout timeout
            municipality = addressInfo?.results?[0]?.street?.municipality
            callback municipality
            return
    request.on 'error', (error) =>
        console.error 'Error geocoding using servicemap API', error
        callback null
        return

redirector = (req, res) ->
    specs = extractSpecification(req)
    resource = getResource specs
    if resource == 'address' and not specs.address.municipality?
        getMunicipalityFromGeocoder specs.address, specs.language.id, (municipality) ->
            if municipality?
                specs.address.municipality = municipality
            else
                specs.address.municipality = 'helsinki'
            url = generateUrl(specs, req.originalUrl)
            res.redirect 301, url
        return
    else
        url = generateUrl(specs, req.originalUrl)
        res.redirect 301, url
        return

module.exports = redirector
