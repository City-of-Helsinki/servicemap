express = require 'express'
config = require 'config'
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

# Handler for '/'
server.get config.url_prefix, (req, res) ->
    res.render 'home.jade', {config_json: config_str, config: config}

server.listen server_port
