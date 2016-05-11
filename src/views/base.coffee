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

        _minifyElement: ($el, $mockEl) ->
            console.trace()
            $mockEl
                .removeClass 'top'
                .addClass 'bottom'
                .css 'visibility', 'visible'
            $el.hide()

        _maximizeElement: ($el, $mockEl) ->
            $mockEl
                .removeClass 'bottom'
                .addClass 'top'
                .css 'visibility', 'hidden'
            $el.show()
            #$el.trigger 'touchstart'
            #$el.scrollTop($el.scrollTop() + 30)
            # $contentEl = $el.children '.content'
            # { contentPadding,
            #   offset,
            #   scrollTop } = @storedToggleValues
            # $el
            #     .css 'overflow-y', 'auto'
            #     .offset offset
            # $contentEl
            #     .css 'padding-top', contentPadding
            #     .scrollTop scrollTop

        _initializeMobileScrollMinification: ->
            { $limitedElement,
              $scrollingContainer,
              $persistentMinifiedElement
            } = @_get$Elements()

            # Set the sidebar content max height for proper scrolling.
            delta = @$el.find('.limit-max-height').height() - $limitedElement.outerHeight()
            currentPadding = Number.parseFloat $limitedElement.css('padding-top')
            return if Number.isNaN currentPadding

            if delta > 0
                currentPadding += delta

            bottomMinifiedElementHeight =
                $persistentMinifiedElement.outerHeight true

            additionalPadding = (
                $scrollingContainer.outerHeight() -
                currentPadding -
                bottomMinifiedElementHeight
            )

            @initialScroll = additionalPadding
            $limitedElement.css 'padding-top', "#{$scrollingContainer.outerHeight() - bottomMinifiedElementHeight}px"

            MINIFIED_SCROLL_POSITION = 10
            MINIFIED_SCROLL_SNAP_TO_BUFFER_HEIGHT = 20
            FIXED_TOP = @$el.find('#fixed-details-header').offset().top

            $detailsHeaderWrapper = @$el.find('#details-header-wrapper').parent()
            $scrollingHeader = @$el.find('#scrolling-details-header')
            $detailsViewArea = $scrollingContainer.find('.content .details-view-area')

            touchActive = false
            animationActive = false
            minified = false
            detailsHeaderWrapperVisible = false

            scrollHandler = (ev) =>
                if (minified or animationActive) then return

                scrollingHeaderOffset = $scrollingHeader.offset().top
                if scrollingHeaderOffset <= FIXED_TOP + 4 and not detailsHeaderWrapperVisible
                    detailsHeaderWrapperVisible = true
                    $detailsHeaderWrapper.css 'visibility', 'visible'
                if scrollingHeaderOffset > FIXED_TOP + 4 and detailsHeaderWrapperVisible
                    detailsHeaderWrapperVisible = false
                    $detailsHeaderWrapper.css 'visibility', 'hidden'

                if touchActive or $scrollingContainer.scrollTop() > MINIFIED_SCROLL_POSITION - 4
                    return
                @_minifyElement $scrollingContainer, $detailsHeaderWrapper
                minified = true

                initialY = null
                touchDown = (ev) =>
                    minified = false
                    @_maximizeElement $scrollingContainer, $detailsHeaderWrapper
                    initialY = ev?.touches?[0]?.pageY or null

                $detailsHeaderWrapper.one 'click', =>
                    touchDown()
                    $scrollingContainer.scrollTop 100

                touchMove = (ev) =>
                    pageY = ev.touches[0].pageY
                    deltaY = initialY - pageY
                    $scrollingContainer.scrollTop deltaY

                el = $detailsHeaderWrapper.get 0
                el.addEventListener 'touchmove', touchMove
                el.addEventListener 'touchstart', touchDown
                el.addEventListener 'touchend', =>
                    el.removeEventListener 'touchmove', touchMove
                    el.removeEventListener 'touchstart', touchDown

            $(window).on 'touchstart', =>
                touchActive = true
            $(window).on 'touchend', =>
                touchActive = false
                scrollHandler()
            $scrollingContainer.scrollTop additionalPadding
            $scrollingContainer.scroll scrollHandler

        alignToBottom: (callback) ->
            { $limitedElement,
              $scrollingContainer,
              $persistentMinifiedElement } = @_get$Elements()

            $limitedElement.css 'visibility', 'visible'
            if @isMobile()
                # this defer is very much necessary,
                # otherwise the initial scrolltop is not correctly calculated
                _.defer _.bind(@_initializeMobileScrollMinification, @)
            if @isMobile()
                @$el.find('#details-view-container').scrollTop 0
            callback?()


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
