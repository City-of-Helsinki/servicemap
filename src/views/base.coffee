define [
    'backbone.marionette',
    'app/jade',
], (
     Marionette,
     jade
)->

    mixOf = (base, mixins...) ->
        class Mixed extends base
        for mixin in mixins by -1 # earlier mixins override later ones
            for name, method of mixin::
                Mixed::[name] = method
        Mixed

    class SMTemplateMixin
        mixinTemplateHelpers: (data) ->
            jade.mixin_helpers data
            return data
        getTemplate: ->
            return jade.get_template @template

    SMItemView: class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin
    SMCollectionView: class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin
    SMLayout: class SMLayout extends mixOf Marionette.Layout, SMTemplateMixin
