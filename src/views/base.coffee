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
            $detailsHeaderWrapper: @$el.find('#details-header-wrapper').parent()
            $scrollingHeader: @$el.find '#scrolling-details-header'
            $fixedDetailsHeader: @$el.find '#fixed-details-header'

        _minifyElement: ($el, $mockEl) ->
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

        _initializeMobileScrollMinification: ->
            {   $limitedElement,
                $scrollingContainer,
                $scrollingHeader,
                $persistentMinifiedElement,
                $detailsHeaderWrapper,
                $fixedDetailsHeader
            } = @_get$Elements()

            # Set the sidebar content max height for proper scrolling.
            delta = @$el.find('.limit-max-height').height() - $limitedElement.outerHeight()
            currentPadding = parseFloat $limitedElement.css('padding-top')
            return if isNaN currentPadding

            if delta > 0
                currentPadding += delta

            bottomMinifiedElementHeight =
                $persistentMinifiedElement.outerHeight true

            additionalPadding = (
                $scrollingContainer.outerHeight() -
                currentPadding -
                bottomMinifiedElementHeight)

            paddingTop = $scrollingContainer.outerHeight() - bottomMinifiedElementHeight
            $limitedElement.css 'padding-top', "#{paddingTop}px"

            MINIFIED_SCROLL_POSITION = 7
            FIXED_TOP = $fixedDetailsHeader.offset().top

            @minified = false

            fixedDetailsHeaderVisible = false
            touchActive = false
            scrollHandler = (ev) =>
                if touchActive or @minified then return true

                offset = $scrollingHeader.offset().top
                if offset <= FIXED_TOP + 4 and not fixedDetailsHeaderVisible
                    fixedDetailsHeaderVisible = true
                    $detailsHeaderWrapper.css 'visibility', 'visible'
                if offset > FIXED_TOP + 4 and fixedDetailsHeaderVisible
                    fixedDetailsHeaderVisible = false
                    $detailsHeaderWrapper.css 'visibility', 'hidden'

                if $scrollingContainer.scrollTop() < MINIFIED_SCROLL_POSITION
                    @_handleScrollElementMinifiedState $scrollingContainer, $detailsHeaderWrapper

            window.addEventListener 'touchstart', => touchActive = true
            window.addEventListener 'touchend', =>
                touchActive = false
                scrollHandler()

            $scrollingContainer.scrollTop additionalPadding
            $scrollingContainer.scroll scrollHandler

        _handleScrollElementMinifiedState: ($scrollingContainer, $detailsHeaderWrapper) ->
            @minified = true
            @_minifyElement $scrollingContainer, $detailsHeaderWrapper

            initialY = null
            touchDown = (ev) =>
                initialY = ev?.touches?[0]?.pageY or null
                @_maximizeElement $scrollingContainer, $detailsHeaderWrapper

            $detailsHeaderWrapper.one 'click', =>
                @_maximizeElement $scrollingContainer, $detailsHeaderWrapper
                $scrollingContainer.scrollTop 100
                @minified = false

            touchMove = (ev) =>
                pageY = ev.touches[0].pageY
                deltaY = initialY - pageY
                if deltaY > 0
                    $scrollingContainer.scrollTop deltaY

            dhw = $detailsHeaderWrapper.get 0
            dhw.addEventListener 'touchmove', touchMove
            dhw.addEventListener 'touchstart', touchDown
            dhw.addEventListener 'touchend', =>
                dhw.removeEventListener 'touchmove', touchMove
                dhw.removeEventListener 'touchstart', touchDown
                if not initialY
                    $scrollingContainer.scrollTop 100
                @minified = false

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
