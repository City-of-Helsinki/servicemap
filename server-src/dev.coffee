express = require 'express'
config = require 'config'
git = require 'git-rev'
jade = require 'jade'

server = express()

for key of config
    val = config[key]
    if typeof val == 'function'
        continue
    console.log "#{key}: #{val}"

server_port = config.server_port or 9001
delete config.server_port

console.log "Listening on port #{server_port}"

config_str = JSON.stringify config

current_commit_id = null
git.short (commit_id) ->
    current_commit_id = commit_id

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
        config_json: config_str
        config: config
        commit_id: current_commit_id
        static_file: static_file_helper
    res.render 'home.jade', vars

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

    # Handler for everything else
    @use config.url_prefix, request_handler

server.listen server_port
