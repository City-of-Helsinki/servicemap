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
            $persistentMinifiedElement: $limitedElement.find('#scrolling-details-header')

        _toggleAway: ($el) ->
            $contentEl = $el.children '.content'
            contentPadding = Number.parseFloat $contentEl.css('padding-top')
            offset = $el.offset()
            @storedToggleValues =
                contentPadding: contentPadding
                offset: offset
                scrollTop: $el.scrollTop()

            offset.top = contentPadding
            $contentEl.css 'padding-top', '0'
            console.log offset
            $el.offset (offset)
            delay (=> $el.scrollTop 0), 100

        alignToBottom: (callback) ->
            {$limitedElement, $scrollingContainer, $persistentMinifiedElement} = @_get$Elements()
            if @isMobile()
                # Set the sidebar content max height for proper scrolling.
                delta = @$el.find('.limit-max-height').height() - $limitedElement.outerHeight()
                _.defer =>
                    currentPadding = Number.parseFloat $limitedElement.css('padding-top')
                    return if Number.isNaN currentPadding
                    if delta > 0
                        currentPadding += delta
                    bottomMinifiedElementHeight =
                        $persistentMinifiedElement.outerHeight(true)

                    console.log $persistentMinifiedElement
                    console.log 'currentPadding', currentPadding
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
                    FIXED_TOP = @$el.find('#fixed-details-header').offset().top
                    $detailsHeaderWrapper = @$el.find('#details-header-wrapper')
                    $scrollingHeader = @$el.find('#scrolling-details-header')
                    _.defer =>
                        $scrollingContainer.scrollTop additionalPadding
                        touchActive = false
                        animationActive = false
                        minified = false
                        scrollHandler = (ev) =>
                            if minified then return
                            position = $scrollingContainer.scrollTop()
                            visibility =
                                if $scrollingHeader.offset().top <= FIXED_TOP
                                    'visible'
                                else
                                    'hidden'
                            $detailsHeaderWrapper.css('visibility', visibility)
                            if touchActive or animationActive then return
                            console.log position, bottomMinifiedElementHeight
                            if position < MINIFIED_SCROLL_POSITION + 20
                                #bottomMinifiedElementHeight
                                #$scrollingContainer.off scroll: scrollHandler
                                if animationActive then return
                                if $scrollingContainer.scrollTop() == MINIFIED_SCROLL_POSITION
                                    return
                                minified = true
                                animationActive = true
                                $scrollingContainer.animate
                                    scrollTop: "#{MINIFIED_SCROLL_POSITION}px",
                                    100, 'swing', =>
                                        animationActive = false
                                        console.log $scrollingContainer.scrollTop()
                                        console.log 'FINALLY', $scrollingContainer.scrollTop()                                        
                                        _.defer => @_toggleAway($scrollingContainer)
                                        #$scrollingContainer.css 'overflow-y': 'hidden'
                                        #$scrollingContainer.css 'pointer-events': 'none'
                                        # console.log ev.cancelable
                                        # ev.preventDefault()
                                        # ev.stopPropagation()
                                        #$scrollingContainer.find('.content .details-view-area').css('pointer-events': 'initial').click (ev) =>
                                        #    console.log 'CLICK -> disable map mode'
                        #scrollHandler = _.throttle(scrollHandler, 100, leading: false)
                        $scrollingContainer.scroll scrollHandler
                        $(window).on 'touchstart', => touchActive = true
                        $(window).on 'touchend', =>
                            touchActive = false
                            scrollHandler()
                        #     return true
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
