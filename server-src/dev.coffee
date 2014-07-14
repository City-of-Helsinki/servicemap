express = require 'express'
config = require 'config'
git = require 'git-rev'

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

server.configure ->
    static_dir = __dirname + '/../static'
    @use config.url_prefix, express.static static_dir
    @locals.pretty = true
    @engine '.jade', require('jade').__express

current_commit_id = null
git.short (commit_id) ->
    current_commit_id = commit_id

# Handler for '/'
server.get config.url_prefix, (req, res) ->
    vars =
        config_json: config_str
        config: config
        commit_id: current_commit_id
    res.render 'home.jade', vars

server.listen server_port
