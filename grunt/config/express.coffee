path = require 'path'

module.exports = (grunt, options) ->
  return {
    options:
      port: 9001
      spawn: true
    dev:
      options:
        script: 'server-js/dev.js'
  }
