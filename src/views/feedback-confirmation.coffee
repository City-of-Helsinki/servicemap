define [
    'app/views/base',
], (
    base,
) ->

    class FeedbackConfirmationView extends base.SMItemView
        template: 'feedback-confirmation'
        className: 'content modal-dialog'
        events:
            'click .ok-button': '_close'
        initialize: (@unit) ->
        serializeData: ->
            unit: @unit.toJSON()
        _close: ->
            app.commands.execute 'closeFeedback'
