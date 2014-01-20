express = require 'express'
server = express()

server.configure ->
    static_dir = __dirname + '/../static'
    @use express.static static_dir
    @locals.pretty = true
    @engine '.jade', require('jade').__express

server.get '/', (req, res) ->
    res.render 'index.jade'

server.listen 9001
