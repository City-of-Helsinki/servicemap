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

server.configure ->
    static_dir = __dirname + '/../static'
    @locals.pretty = true
    @engine '.jade', jade.__express

    # Static files handler
    @use config.url_prefix, express.static static_dir

    static_file = (fpath) ->
        config.url_prefix + fpath

    # Handler for everything else
    @use config.url_prefix, (req, res, next) ->
        vars =
            config_json: config_str
            config: config
            commit_id: current_commit_id
            static_file: static_file
        res.render 'home.jade', vars

server.listen server_port
