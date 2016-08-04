define (require) ->
    _          = require 'underscore'
    Marionette = require 'backbone.marionette'

    jade       = require 'cs!app/jade'
    animations = require 'cs!app/animations'

    class SidebarRegion extends Marionette.Region

        SUPPORTED_ANIMATIONS = ['left', 'right']

        _trigger: (eventName, view) =>
            Marionette.triggerMethod.call(@, eventName, view)
            if _.isFunction view.triggerMethod
                view.triggerMethod eventName
            else
                Marionette.triggerMethod.call(view, eventName)

        show: (view, options) =>
            showOptions = options or {}
            @_ensureElement()
            isViewClosed = view.isDestroyed or _.isUndefined(view.$el)
            isDifferentView = view != @currentView
            preventClose =  !!showOptions.preventClose
            _shouldCloseView = not preventClose and isDifferentView
            animationType = showOptions.animationType
            $oldContent = @currentView?.$el

            shouldAnimate = $oldContent?.length and animationType in SUPPORTED_ANIMATIONS and view.template?

            # RENDER WITH ANIMATIONS
            # ----------------------
            if shouldAnimate
                data = view.serializeData?() or {}
                templateString = jade.template view.template, data
                $container = @$el
                $newContent = view.$el.append($(templateString))

                @_trigger('before:render', view)
                @_trigger('before:show', view)

                animationCallback = =>
                    @close() if _shouldCloseView
                    @currentView = view
                    @_trigger('render', view)
                    @_trigger('show', view)

                animations.render($container, $oldContent, $newContent, animationType, animationCallback)

            # RENDER WITHOUT ANIMATIONS
            # -------------------------
            else
                # Close the old view
                @close() if _shouldCloseView

                view.render()
                @_trigger('before:show', view)

                # Attach the view's Html to the region's el
                if isDifferentView or isViewClosed
                    @open view

                @currentView = view
                @_trigger('show', view)

            return @

        # Close the currentView
        close: ->
            view = @currentView
            return if not view or view.isDestroyed

            # call 'destroy' or 'remove', depending on which is found
            if view.destroy
                view.destroy()
            else if view.remove
                view.remove()

            Marionette.triggerMethod.call(@, 'destroy', view)
            delete @currentView

    return SidebarRegion
