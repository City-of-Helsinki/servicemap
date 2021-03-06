define (require) ->
    Marionette = require 'backbone.marionette'

    jade       = require 'cs!app/jade'
    {mixOf}    = require 'cs!app/base'

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
                    when 'esc' then 27
            handle = _.bind(callback, @)
            (event) =>
                event.stopPropagation()
                if event.which in codes then handle event

    class ToggleMixin
        toggleCollapse: (ev) ->
            ev.preventDefault()
            @collapsed = !@collapsed
            if @collapsed
                @hideContents()
            else
                @showContents()
            @setMaxHeight()

        setMaxHeight: ->
            $limitedElement = @$el.find('.limit-max-height')
            return unless $limitedElement.length
            maxHeight = $(window).innerHeight() - $limitedElement.offset().top
            $limitedElement.css 'max-height': maxHeight

    class ReadyMixin
        isReady: -> true

    SMItemView: class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin, KeyboardHandlerMixin, ReadyMixin
    SMCollectionView: class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin, KeyboardHandlerMixin, ReadyMixin
    SMLayout: class SMLayout extends mixOf Marionette.LayoutView, SMTemplateMixin, KeyboardHandlerMixin, ToggleMixin, ReadyMixin
    SMCompositeView: class SMCompositeView extends mixOf Marionette.CompositeView, SMTemplateMixin, ToggleMixin, ReadyMixin
