express = require 'express'
config = require 'config'
git = require 'git-rev-sync'
jade = require 'jade'
https = require 'https'
slashes = require 'connect-slashes'
legacyRedirector = require './legacy-redirector'
raven = require 'raven'
util = require 'util'

init_config = ->
    console.log 'Configuration in use:\n---------------------'
    for own key of config
        val = util.inspect config.get key
        console.log "#{key}: #{val}"
    console.log '---------------------'

    config.git_commit_id = git.long()
    config.server.ALLOWED_URLS = [
        /^\/$/
        /^\/unit\/\d+$/, # with id
        /^\/unit$/, # with query string
        /^\/search$/, # with query string
        /^\/address\/[^\/]+\/[^\/]+\/[^\/]+$/, # with id path
        /^\/division\/[^\/]+\/[^\/]+$/, # with id path
        /^\/division$/, # with query string
        /^\/area$/
    ]

    if config.has 'raven_dsn'
        ravenClient = new raven.Client config.get 'raven_dsn'
        ravenClient.patchGlobal()
        console.log "Raven configured for #{config.get 'raven_dsn'}"

staticFileHelper = (fpath) ->
    config.get('static_path') + fpath

get_language = (host) ->
    if host.match /^servicemap\./
        'en'
    else if host.match /^servicekarta\./
        'sv'
    else
        'fi'

makeHandler = (template, options) ->
    requestHandler = (req, res, next) ->
        unless req.path? and req.hostname?
            next()
            return
        match = false
        for pattern in config.get 'server.ALLOWED_URLS'
            if req.path.match pattern
                match = true
                break
        if not match
            next()
            return
        if req.query.treenode?
            fullUrl = req.originalUrl.replace(/treenode/g, 'service_node');
            res.redirect 301, fullUrl
        host = req.hostname
        config.default_language = get_language host
        config.is_embedded = options.embedded

        client_config = config.util.toObject()
        delete(client_config.server)

        vars =
            configJson: JSON.stringify client_config
            config: config
            staticFile: staticFileHelper
            pageMeta: req._context or {}
            siteName:
                fi: 'Pääkaupunkiseudun palvelukartta'
                sv: 'Servicekarta'
                en: 'Service Map'

        res.render template, vars

# This handler can be removed once it's certain it
# has no users.
redirectHandler = (req, res, next) ->
    if req.path.match /^\/area/
        bbox = req.query.bbox
        if bbox?
            res.redirect 301, config.url_prefix + "embed?bbox=#{bbox}&level=all"
            return
    else if req.path.match /^\/unit/
        divs = req.query.divisions
        if divs?
            res.redirect 301, config.url_prefix + "embed/division?ocd_id=#{divs}&level=all"
            return
    next()

handleUnit = (req, res, next) ->
    if req.query.service? or req.query.division? or req.query.service_node? or req.query.treenode?
        requestHandler req, res, next
        return
    pattern = /^\/(\d+)\/?$/
    r = req.path.match pattern
    if not r or r.length < 2
        res.redirect config.url_prefix
        return

    unitId = r[1]
    url = config.service_map_backend + '/unit/' + unitId + '/'
    unitInfo = null

    sendResponse = ->
        if unitInfo and unitInfo.name
            context =
                title: unitInfo.name.fi
                description: unitInfo.description
                picture: unitInfo.picture_url
                url: req.protocol + '://' + req.get('host') + req.originalUrl
        else
            context = null
        req._context = context
        next()

    timeout = setTimeout sendResponse, 2000

    request = https.get url, (httpResp) ->
        if httpResp.statusCode != 200
            clearTimeout timeout
            sendResponse()
            return

        respData = ''
        httpResp.on 'data', (data) ->
            respData += data
        httpResp.on 'end', ->
            unitInfo = JSON.parse respData
            clearTimeout timeout
            sendResponse()
    request.on 'error', (error) =>
        console.error 'Error making API request', error

init_server = ->
    # For serving during development
    staticDir = __dirname + '/../static'

    server = express()
    server.enable 'strict routing'

    server.locals.pretty = true
    server.engine '.jade', jade.__express

    if false
        # Setup request logging
        server.use (req, res, next) ->
            console.log '%s %s', req.method, req.url
            next()

    static_path = config.get('static_path')
    url_prefix = config.get('url_prefix')

    # Static files handler
    server.use static_path, express.static staticDir
    server.use url_prefix + 'embed', redirectHandler
    server.use url_prefix + 'rdr', legacyRedirector
    # Redirect all trailing slash urls to slashless urls
    server.use slashes(false)
    # Expose the original sources for better debugging
    server.use url_prefix + 'src', express.static(__dirname + '/../src')

    # Emit unit data server side for robots
    server.use url_prefix + 'unit', handleUnit
    # Handler for embed urls
    server.use url_prefix + 'embed', makeHandler('embed.jade', {embedded: true})
    # Handler for everything else
    server.use url_prefix, makeHandler('home.jade', {embedded: false})

init_config()
server = init_server()

console.log "Starting server on port #{config.get 'server.port'}"
server.listen(config.get 'server.port', config.get 'server.address')
