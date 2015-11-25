define [
    'cs!app/views/base',
], (
    base
) ->

    class ToolMenuItem extends base.SMItemView
        className: 'context-menu-item'
        tagName: 'li'
        template: 'context-menu-item'
        initialize: (opts) ->
            super opts
            @$el.on 'click', @model.get('action')

    class ContextMenuCollectionView extends base.SMCollectionView
        className: 'context-menu'
        tagName: 'ul'
        itemView: ToolMenuItem

    class ContextMenuView extends base.SMLayout
        className: 'context-menu-wrapper'
        template: 'context-menu-wrapper'
        initialize: (@opts) ->
        regions:
            contents: '.contents'
        onRender: ->
            @contents.show new ContextMenuCollectionView @opts

    ContextMenuView
