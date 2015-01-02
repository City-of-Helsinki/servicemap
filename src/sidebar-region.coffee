reqs = ['underscore', 'backbone.marionette', 'app/jade', 'app/animations']

define 'app/sidebar-region', reqs, (_, Marionette, jade, animations) ->

    class SidebarRegion extends Marionette.Region

        SUPPORTED_ANIMATIONS = ['left', 'right']

        _trigger: (event_name, view) =>
            Marionette.triggerMethod.call(@, event_name, view)
            if _.isFunction view.triggerMethod
                view.triggerMethod event_name
            else
                Marionette.triggerMethod.call(view, event_name)

        show: (view, options) =>
            showOptions = options or {}
            @ensureEl()
            isViewClosed = view.isClosed or _.isUndefined(view.$el)
            isDifferentView = view != @currentView
            preventClose =  !!showOptions.preventClose
            _shouldCloseView = not preventClose and isDifferentView
            animation_type = showOptions.animation_type
            $old_content = @currentView?.$el

            should_animate = $old_content?.length and animation_type in SUPPORTED_ANIMATIONS and view.template?

            # RENDER WITH ANIMATIONS
            # ----------------------
            if should_animate
                data = view.serializeData?() or {}
                template_string = jade.template view.template, data
                $container = @$el
                $new_content = view.$el.append($(template_string))

                @_trigger('before:render', view)
                @_trigger('before:show', view)

                animation_callback = =>
                    @close() if _shouldCloseView
                    @currentView = view
                    @_trigger('render', view)
                    @_trigger('show', view)

                animations.render($container, $old_content, $new_content, animation_type, animation_callback)

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
            return if not view or view.isClosed

            # call 'close' or 'remove', depending on which is found
            if view.close
                view.close()
            else if view.remove
                view.remove()

            Marionette.triggerMethod.call(@, 'close', view)
            delete @currentView

    return SidebarRegion
