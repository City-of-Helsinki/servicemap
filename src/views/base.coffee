define [
    'backbone.marionette',
    'app/jade',
    'app/base'
], (
     Marionette,
     jade,
     mixOf: mixOf
)->


    class SMTemplateMixin
        mixinTemplateHelpers: (data) ->
            jade.mixinHelpers data
            return data
        getTemplate: ->
            return jade.getTemplate @template

    class KeyboardHandlerMixin
        keyboardHandler: (callback, keys) =>
            codes = _(keys).map (key) =>
                switch key
                    when 'enter' then 13
                    when 'space' then 32
            handle = _.bind(callback, @)
            (event) =>
                event.stopPropagation()
                if event.which in codes then handle event

    SMItemView: class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin, KeyboardHandlerMixin
    SMCollectionView: class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin, KeyboardHandlerMixin
    SMLayout: class SMLayout extends mixOf Marionette.Layout, SMTemplateMixin, KeyboardHandlerMixin
