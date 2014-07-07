reqs = ['underscore', 'backbone.marionette', 'app/jade', 'app/animations']

define 'app/sidebar-region', reqs, (_, Marionette, jade, animations) ->

    class SidebarRegion extends Marionette.Region

        # get_animation_type: (view) ->
        #     # console.log '@currentView?.type', @currentView?.type
        #     # console.log 'view?.type', view?.type
        #     if (
        #         @currentView?.type in ['service-tree', 'details', 'event'] and
        #         view?.type in ['service-tree', 'details', 'event']
        #     )
        #         return 'left'
        #     else
        #         return null

        _trigger: (event_name, view) =>
            console.log '--> trigger!', event_name
            Marionette.triggerMethod.call(@, event_name, view)
            if _.isFunction view.triggerMethod
                view.triggerMethod event_name
            else
                Marionette.triggerMethod.call(view, event_name)

        show: (view, options) =>
            console.log '\n\n----> sidebar-region show', view.type or '????'
            #debugger
            @ensureEl()
            showOptions = options or {}
            isViewClosed = view.isClosed or _.isUndefined(view.$el)
            isDifferentView = view != @currentView
            preventClose =  !!showOptions.preventClose
            _shouldCloseView = not preventClose and isDifferentView
            #preventAnimation = !!showOptions.preventAnimation

            # console.log '\n\nsidebar region show'
            # console.log '@currentView', @currentView
            # console.log 'view', view
            # console.log view.type or '?????? was the type'
            # console.log '\nisDifferentView', isDifferentView
            # console.log '_shouldCloseView', _shouldCloseView


            # ANIMATIONS COME HERE
            # --------------------
            # animation_type = @get_animation_type(view)
            animation_type = showOptions.animation_type
            $old_content = @currentView?.$el
            should_animate = $old_content?.length and animation_type and view.template?

            # Add content with animations
            if should_animate
                data = view.serializeData?() or {}
                template_string = jade.template view.template, data
                $container = @$el
                $new_content = view.$el.append($(template_string))

                @_trigger('before:render', view)
                @_trigger('before:show', view)

                # console.log 'currentView', @currentView
                # console.log '@currentView?.$el', @currentView?.$el
                # console.log 'view.$el', view.$el, '<-------------------------'

                animation_callback = =>
                    @close {animate: false} if _shouldCloseView
                    @currentView = view
                    @_trigger('render', view)
                    @_trigger('show', view)

                animations.render($container, $old_content, $new_content, 'left', animation_callback)

            # Add content without animations
            else

                # Close the old view
                @close {animate: false} if _shouldCloseView

                view.render()

                @_trigger('before:show', view)

                # Attach the view's Html to the region's el
                #console.log 'isDifferentView', isDifferentView
                #console.log 'isViewClosed', isViewClosed
                #console.log 'isDifferentView or isViewClosed', isDifferentView or isViewClosed
                if isDifferentView or isViewClosed
                    @open view

                @currentView = view

                @_trigger('show', view)

            return @


        # Close the view, animating it out first if it needs to be
        close: (options) ->
            console.log '----> sidebar-region close', @currentView?.type or '????'
            options = options or {}

            view = @currentView
            return if not view or view.isClosed

            # Animate by default
            animate = if options.animate? then options.animate else true

            # Animate the view before destroying it if a function exists. Otherwise,
            # immediately destroy it
            if _.isFunction view.animateOut and animate
                @listenToOnce(@currentView, 'animateOut', _.bind(@_destroyView, @))
                @currentView.animateOut()
            else
                @_destroyView()

        _destroyView: ->
            console.log '----> sidebar-region destroy'
            view = @currentView
            return if not view or view.isClosed

            # call 'close' or 'remove', depending on which is found
            if view.close
                view.close()
            else if view.remove
                view.remove()

            Marionette.triggerMethod.call(@, 'close', view)

            #console.log '---------- DELETE CURRENT_VIEW ------------'
            delete @currentView

        # This is essentially the show fn
        _onTransitionOut: (view, options) ->
            console.log 'sidebar-region transition out'
            Marionette.triggerMethod.call(@, 'animateOut', @currentView)

            showOptions = options or {}
            isViewClosed = view.isClosed or _.isUndefined(view.$el)
            #console.log 'view', view
            #console.log '@currentView', @currentView
            #console.log 'view != @currentView', view != @currentView
            isDifferentView = view != @currentView
            preventClose =  !!showOptions.preventClose

            # only close the view if we don't want to preventClose and the view is different
            _shouldCloseView = not preventClose and isDifferentView

            # The region is only animating if there's an animateIn method on the new view
            animatingIn = _.isFunction(view.animateIn)

            #console.log 'animatingIn', animatingIn

            # Close the old view
            @close {animate: false} if _shouldCloseView

            # Render the new view, then hide its $el
            view.render()

            # before:show triggerMethods
            Marionette.triggerMethod.call(@, 'before:show', view)
            if _.isFunction(view.triggerMethod)
                view.triggerMethod 'before:show'
            else
                Marionette.triggerMethod.call(view, 'before:show')

            # Only hide the view if we want to animate it
            view.$el.css {'opacity': 0} if animatingIn

            # Attach the view's Html to the region's el
            #console.log 'isDifferentView', isDifferentView
            #console.log 'isViewClosed', isViewClosed
            #console.log 'isDifferentView or isViewClosed', isDifferentView or isViewClosed
            if isDifferentView or isViewClosed
                @open view

            @currentView = view

            # show triggerMethods
            Marionette.triggerMethod.call(@, 'show', view)
            if _.isFunction view.triggerMethod
                view.triggerMethod 'show'
            else
                Marionette.triggerMethod.call(view, 'show')

            # If there's an animateIn method, then call it and wait for it to complete
            if animatingIn
                @listenToOnce(view, 'animateIn', _.bind(@_onTransitionIn, @))
                view.animateIn()

            # Otherwise, continue on
            else
                return @_onTransitionIn()

        # After it's shown, then we triggerMethod 'animateIn'
        _onTransitionIn: ->
            console.log 'sidebar region transition in'
            Marionette.triggerMethod.call(@, 'animateIn', @currentView)
            return @

    return SidebarRegion
