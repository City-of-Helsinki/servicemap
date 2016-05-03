define [
    'backbone.marionette',
    'cs!app/jade',
    'cs!app/base',
    'cs!app/util/navigation',
], (
    Marionette,
    jade,
    {mixOf: mixOf},
    NavigationUtils
) ->
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
            unless @collapsed
                NavigationUtils.checkLocationHash()

        setMaxHeight: ->
            $limitedElement = @$el.find('.limit-max-height')
            return unless $limitedElement.length
            maxHeight = $(window).innerHeight() - $limitedElement.offset().top
            $limitedElement.css 'max-height': maxHeight

        handleCollapsedState: ->
            if @collapsed
                @$el.find('#details-view-container').hide()
            else
                @$el.find('#details-view-container').show()
            event = if @collapsed then 'maximize' else 'minimize'
            app.vent.trigger "mapview-activearea:#{event}"

    class SMLayout extends mixOf(
        Marionette.Layout,
        SMTemplateMixin,
        KeyboardHandlerMixin,
        ToggleMixin
    )

    DETAILS_BODY_CLASS = 'details-view'

    class DetailsLayout extends SMLayout
        addBodyClass: ->
            $('body').toggleClass DETAILS_BODY_CLASS, true
        removeBodyClass: ->
            $('body').toggleClass DETAILS_BODY_CLASS, false
        onClose: ->
            @removeBodyClass()
        isMobile: ->
            $(window).width() <= appSettings.mobile_ui_breakpoint
        _get$Elements: ->
            $limitedElement = @$el.find '.content'
            $limitedElement: $limitedElement
            $scrollingContainer: $limitedElement.parent()
            $persistentMinifiedElement: $limitedElement
                .children().first()
                .children().first()
                .children('.header').first()
        alignToBottom: (callback) ->
            {$limitedElement, $scrollingContainer, $persistentMinifiedElement} = @_get$Elements()
            if @isMobile()
                # Set the sidebar content max height for proper scrolling.
                delta = @$el.find('.limit-max-height').height() - $limitedElement.outerHeight()
                _.defer =>
                    currentPadding = Number.parseFloat $limitedElement.css('padding-top')
                    console.log 'currentPadding', currentPadding
                    return if Number.isNaN currentPadding
                    if delta > 0
                        currentPadding += delta
                    console.log $persistentMinifiedElement
                    bottomMinifiedElementHeight =
                        $persistentMinifiedElement.outerHeight(true)
                    console.log bottomMinifiedElementHeight
                    console.log $scrollingContainer.outerHeight(), currentPadding, bottomMinifiedElementHeight
                    additionalPadding = (
                        $scrollingContainer.outerHeight() -
                        currentPadding -
                        bottomMinifiedElementHeight
                    )
                    @initialScroll = additionalPadding
                    $limitedElement.css 'padding-top', "#{$scrollingContainer.outerHeight() - bottomMinifiedElementHeight}px"

                    MINIFIED_SCROLL_POSITION = 10
                    _.defer =>
                        $scrollingContainer.scrollTop additionalPadding
                        touchActive = false
                        animationActive = false
                        scrollHandler = (ev) =>
                            position = $scrollingContainer.scrollTop()
                            if position >= 507
                                @$el.find('#details-header-wrapper').css('display', 'block')
                            else
                                @$el.find('#details-header-wrapper').css('display', 'none')
                            console.log position
                            if touchActive or animationActive then return
                            if position < bottomMinifiedElementHeight
                                #$scrollingContainer.off scroll: scrollHandler
                                if animationActive then return
                                animationActive = true
                                if $scrollingContainer.scrollTop() == MINIFIED_SCROLL_POSITION
                                    return
                                $scrollingContainer.animate
                                    scrollTop: "#{MINIFIED_SCROLL_POSITION}px",
                                    100, 'swing', =>
                                        animationActive = false
                                        $scrollingContainer.css 'overflow-y': 'hidden'
                                        $scrollingContainer.css 'pointer-events': 'none'
                                        $scrollingContainer.find('.content .details-view-area').css('pointer-events': 'initial').click (ev) =>
                                            console.log 'CLICK -> disable map mode'
                        scrollHandler = _.throttle(scrollHandler, 100)
                        $scrollingContainer.scroll scrollHandler
                        $(window).on 'touchstart', => touchActive = true
                        $(window).on 'touchend', =>
                            touchActive = false
                            scrollHandler()
                            return true
            _.defer =>
                $limitedElement.css 'visibility', 'visible'
                callback?()
        resetScroll: ->
            unless @isMobile() or !@initialScroll?
                return
            {$scrollingContainer} = @_get$Elements()
            $scrollingContainer.scrollTop @initialScroll


    return {
        SMItemView: class SMItemView extends mixOf(
            Marionette.ItemView,
            SMTemplateMixin,
            KeyboardHandlerMixin
        )
        SMCollectionView: class SMCollectionView extends mixOf(
            Marionette.CollectionView,
            SMTemplateMixin,
            KeyboardHandlerMixin
        )
        SMLayout: SMLayout
        DetailsLayout: DetailsLayout
    }
