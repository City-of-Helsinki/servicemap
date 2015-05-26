define [
    'app/views/base',
], (
    base
) ->

    class AccessibilityPersonalisationView extends base.SMItemView
        className: 'accessibility-personalisation'
        template: 'accessibility-personalisation'
        initialize: (@activeModes) ->
        serializeData: ->
            accessibility_viewpoints: @activeModes
