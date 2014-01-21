express = require 'express'
config = require 'config'
server = express()

for key of config
    val = config[key]
    if typeof val == 'function'
        continue
    console.log "#{key}: #{val}"

server.configure ->
    static_dir = __dirname + '/../static'
    @use express.static static_dir
    @locals.pretty = true
    @engine '.jade', require('jade').__express

server.get '/', (req, res) ->
    res.render 'index.jade', config: config

server.listen 9001
