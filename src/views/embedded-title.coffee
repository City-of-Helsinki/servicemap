define [
    'cs!app/p13n',
    'cs!app/jade',
    'cs!app/views/base',
    'URI'
], (
    p13n,
    jade,
    base,
    URI
)  ->

    class TitleView extends base.SMItemView
        initialize: ({href: @href}) ->
        className:
            'title-control'
        render: =>
            @el.innerHTML = jade.template 'embedded-title', lang: p13n.getLanguage(), href: @href
            @el
