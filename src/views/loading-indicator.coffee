define (require) ->
    {SMLayout} = require 'cs!app/views/base'

    class LoadingIndicatorView extends SMLayout
        className: 'loading-indicator'
        template: 'loading-indicator'
        initialize: (opts) ->
            @message = opts.message
        serializeData: ->
            message: @message
