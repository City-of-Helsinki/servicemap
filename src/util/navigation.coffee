define (require) ->
    Backbone = require 'backbone'

    isFrontPage: =>
        Backbone.history.fragment == ''
