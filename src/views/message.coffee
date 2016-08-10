define (require) ->
    {SMLayout} = require 'cs!app/views/base'

    class MessageLayout extends SMLayout
        # used to render a message or hint in the navigation region (sidebar)
        template: 'message-layout'
        className: 'navigation-element'
        regions: messageContents: '.main-list .info-box'
        initialize: ({model}) -> @childView = new @childClass model: model
        onShow: -> @messageContents.show @childView

    class InformationalMessageLayout extends SMLayout
        # show the user a notification informing
        # that the current url route contains no
        # units (eg. due to an empty/non-existent service)
        template: 'message-informational'
        className: 'message-contents message-informational'
        tagName: 'p'

    class InformationalMessageView extends MessageLayout
        childClass: InformationalMessageLayout

    {InformationalMessageView}
