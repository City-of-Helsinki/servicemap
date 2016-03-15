define [
    'backbone.marionette',
    'cs!app/jade',
    'cs!app/base'
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

    class ToggleMixin
        toggleCollapse: (ev) ->
            ev.preventDefault()
            @collapsed = !@collapsed
            @render()
            @setMaxHeight()

        setMaxHeight: ->
            $limitedElement = @$el.find('.limit-max-height')
            return unless $limitedElement.length
            maxHeight = $(window).innerHeight() - $limitedElement.offset().top
            $limitedElement.css 'max-height': maxHeight

    class SMLayout extends mixOf Marionette.Layout, SMTemplateMixin, KeyboardHandlerMixin, ToggleMixin

    class DetailsLayout extends SMLayout
        alignToBottom: ->
            # Set the sidebar content max height for proper scrolling.
            $limitedElement = @$el.find '.content'
            delta = @$el.innerHeight() - $limitedElement.outerHeight()
            if delta > 0
                currentPadding = Number.parseFloat $limitedElement.css('padding-top')
                $limitedElement.css 'padding-top', "#{delta + currentPadding}px"
            show = =>
                $limitedElement.css 'visibility', 'visible'
            _.delay show, 500 # TODO: wtf does it take so long?
        onRender: ->
            @alignToBottom()

    SMItemView: class SMItemView extends mixOf Marionette.ItemView, SMTemplateMixin, KeyboardHandlerMixin
    SMCollectionView: class SMCollectionView extends mixOf Marionette.CollectionView, SMTemplateMixin, KeyboardHandlerMixin
    SMLayout: SMLayout
    DetailsLayout: DetailsLayout
