define ['cs!app/views/base'], (base) ->

    class LocationRefreshButtonView extends base.SMLayout
        template: 'location-refresh-button'
        events:
            'click': 'resetPosition'
        resetPosition: (ev) ->
            ev.stopPropagation()
            ev.preventDefault()
            app.commands.execute 'resetPosition'
        render: ->
            super()
            @el
