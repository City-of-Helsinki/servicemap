define ['backbone'], (Backbone) ->

    isFrontPage: =>
        Backbone.history.fragment == ''

    checkLocationHash: () ->
        hash = window.location.hash.replace /^#!/, '#'
        if hash
            app.vent.trigger 'hashpanel:render', hash
