define (require) ->
    URI  = require 'URI'

    p13n = require 'cs!app/p13n'
    jade = require 'cs!app/jade'
    base = require 'cs!app/views/base'

    class TitleView extends base.SMItemView
        initialize: ({href: @href}) ->
        className:
            'title-control'
        render: =>
            @el.innerHTML = jade.template 'embedded-title', lang: p13n.getLanguage(), href: @href
            @el
