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

    SMItemView: class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin
    SMCollectionView: class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin
    SMLayout: class SMLayout extends mixOf Marionette.Layout, SMTemplateMixin
