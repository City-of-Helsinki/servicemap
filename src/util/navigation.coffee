define ['backbone'], (Backbone) ->

    isFrontPage: =>
        Backbone.history.fragment == ''
