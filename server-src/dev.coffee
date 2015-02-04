express = require 'express'
config = require 'config'
git = require 'git-rev'
jade = require 'jade'
http = require 'http'

server = express()

for key of config
    val = config[key]
    if typeof val == 'function'
        continue
    console.log "#{key}: #{val}"

serverPort = config.server_port or 9001
delete config.server_port

console.log "Listening on port #{serverPort}"

git.short (commitId) ->
    config.git_commit_id = commitId

STATIC_URL = config.static_path
ALLOWED_URLS = [
    /^\/$/
    /^\/unit\/\d+\/?$/,
    /^\/service\/\d+\/?$/,
    /^\/search\/$/,
    /^\/address\/[^\/]+\/[^\/]+$/
]

staticFileHelper = (fpath) ->
    STATIC_URL + fpath

requestHandler = (req, res, next) ->
    match = false
    for pattern in ALLOWED_URLS
        if req.path.match pattern
            match = true
            break
    if not match
        next()
        return

    vars =
        configJson: JSON.stringify config
        config: config
        staticFile: staticFileHelper
        pageMeta: req._context or {}
        siteName:
            fi: 'Pääkaupunkiseudun palvelukartta'
            sv: 'Servicekarta'
            en: 'Service Map'

    res.render 'home.jade', vars

embeddedHandler = (req, res, next) ->
    # TODO: enable
    # match = false
    # for pattern in ALLOWED_URLS
    #     if req.path.match pattern
    #         match = true
    #         break
    # if not match
    #     next()
    #     return

    vars =
        configJson: JSON.stringify config
        config: config
        staticFile: staticFileHelper
        pageMeta: req._context or {}
        siteName:
            fi: 'Pääkaupunkiseudun palvelukartta'
            sv: 'Servicekarta'
            en: 'Service Map'

    res.render 'embed.jade', vars

handleUnit = (req, res, next) ->
    pattern = /^\/(\d+)\/?$/
    r = req.path.match pattern
    if not r or r.length < 2
        res.redirect config.urlPrefix
        return

    unitId = r[1]
    url = config.service_map_backend + '/unit/' + unitId + '/'
    unitInfo = null

    sendResponse = ->
        if unitInfo
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

    http.get url, (httpResp) ->
        respData = ''
        httpResp.on 'data', (data) ->
            respData += data
        httpResp.on 'end', ->
            unitInfo = JSON.parse respData
            clearTimeout timeout
            sendResponse()

server.configure ->
    staticDir = __dirname + '/../static'
    @locals.pretty = true
    @engine '.jade', jade.__express

    if false
        # Setup request logging
        @use (req, res, next) ->
            console.log '%s %s', req.method, req.url
            next()

    # Static files handler
    @use STATIC_URL, express.static staticDir
    # Expose the original sources for better debugging
    @use config.url_prefix + 'src', express.static(__dirname + '/../src')

    @use config.url_prefix + 'unit', handleUnit

    @use config.url_prefix + 'embed', embeddedHandler

    # Handler for everything else
    @use config.url_prefix, requestHandler

server.listen serverPort
