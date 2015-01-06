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

server_port = config.server_port or 9001
delete config.server_port

console.log "Listening on port #{server_port}"

git.short (commit_id) ->
    config.git_commit_id = commit_id

STATIC_URL = config.static_path
ALLOWED_URLS = [
    /^\/$/
    /^\/unit\/\d+\/?$/,
    /^\/service\/\d+\/?$/,
    /^\/search\/$/,
]

static_file_helper = (fpath) ->
    STATIC_URL + fpath

request_handler = (req, res, next) ->
    match = false
    for pattern in ALLOWED_URLS
        if req.path.match pattern
            match = true
            break
    if not match
        next()
        return

    vars =
        config_json: JSON.stringify config
        config: config
        static_file: static_file_helper
        page_meta: req._context or {}

    res.render 'home.jade', vars

handle_unit = (req, res, next) ->
    pattern = /^\/(\d+)\/?$/
    r = req.path.match pattern
    if not r or r.length < 2
        res.redirect config.url_prefix
        return

    unit_id = r[1]
    url = config.service_map_backend + '/unit/' + unit_id + '/'
    unit_info = null

    send_response = ->
        if unit_info
            context =
                title: unit_info.name.fi
                description: unit_info.description
                picture: unit_info.picture_url
                url: req.protocol + '://' + req.get('host') + req.originalUrl
        else
            context = null
        req._context = context
        next()

    timeout = setTimeout send_response, 2000

    http.get url, (http_resp) ->
        resp_data = ''
        http_resp.on 'data', (data) ->
            resp_data += data
        http_resp.on 'end', ->
            unit_info = JSON.parse resp_data
            clearTimeout timeout
            send_response()

server.configure ->
    static_dir = __dirname + '/../static'
    @locals.pretty = true
    @engine '.jade', jade.__express

    if false
        # Setup request logging
        @use (req, res, next) ->
            console.log '%s %s', req.method, req.url
            next()

    # Static files handler
    @use STATIC_URL, express.static static_dir
    # Expose the original sources for better debugging
    @use config.url_prefix + 'src', express.static(__dirname + '/../src')

    @use config.url_prefix + 'unit', handle_unit

    # Handler for everything else
    @use config.url_prefix, request_handler

server.listen server_port
