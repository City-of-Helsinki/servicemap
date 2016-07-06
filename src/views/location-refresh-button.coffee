define (require) ->
    base = require 'cs!app/views/base'

    class LocationRefreshButtonView extends base.SMLayout
        template: 'location-refresh-button'
        events:
            'click': 'resetPosition'
        resetPosition: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.request 'resetPosition'
        render: ->
            super()
            @el
