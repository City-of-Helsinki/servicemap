define [
    'underscore',
    'i18next',
    'app/models'
    'app/views/base',
], (
    _,
    i18n,
    models,
    base
)  ->

    class ServiceTreeView extends base.SMLayout
        id: 'service-tree-container'
        className: 'navigation-element'
        template: 'service-tree'
        events: ->
            openOnKbd = @keyboardHandler @openService, ['enter']
            toggleOnKbd = @keyboardHandler @toggleLeaf, ['enter', 'space']
            'click .service.has-children': 'openService'
            'keydown .service.has-children': openOnKbd
            'click .service.parent': 'openService'
            'keydown .service.parent': openOnKbd
            'click .crumb': 'handleBreadcrumbClick'
            'click .service.leaf': 'toggleLeaf'
            'keydown .service.leaf': toggleOnKbd
            'click .service .show-icon': 'toggleButton'
            'mouseenter .service .show-icon': 'showTooltip'
            'mouseleave .service .show-icon': 'removeTooltip'
        type: 'service-tree'

        initialize: (options) ->
            @selectedServices = options.selectedServices
            @breadcrumbs = options.breadcrumbs
            @animationType = 'left'
            @scrollPosition = 0
            @listenTo @selectedServices, 'remove', @render
            @listenTo @selectedServices, 'add', @render
            @listenTo @selectedServices, 'reset', @render

        toggleLeaf: (event) ->
            @toggleElement($(event.currentTarget).find('.show-icon'))

        toggleButton: (event) ->
            @removeTooltip()
            event.preventDefault()
            event.stopPropagation()
            @toggleElement($(event.target))

        showTooltip: (event) ->
            @removeTooltip()
            @$tooltipElement = $("<div id=\"tooltip\">#{i18n.t('sidebar.show_tooltip')}</div>")
            $targetEl = $(event.currentTarget)
            $('body').append @$tooltipElement
            buttonOffset = $targetEl.offset()
            originalOffset = @$tooltipElement.offset()
            @$tooltipElement.css 'top', "#{buttonOffset.top + originalOffset.top}px"
            @$tooltipElement.css 'left', "#{buttonOffset.left + originalOffset.left}px"
        removeTooltip: (event) ->
            @$tooltipElement?.remove()

        getShowIconClasses: (showing, rootId) ->
            if showing
                return "show-icon selected service-color-#{rootId}"
            else
                return "show-icon service-hover-color-#{rootId}"

        toggleElement: ($targetElement) ->
            serviceId = $targetElement.closest('li').data('service-id')
            unless @selected(serviceId) is true
                app.commands.execute 'clearSearchResults'
                service = new models.Service id: serviceId
                service.fetch
                    success: =>
                        app.commands.execute 'addService', service
            else
                app.commands.execute 'removeService', serviceId

        handleBreadcrumbClick: (event) ->
            event.preventDefault()
            # We need to stop the event from bubling to the containing element.
            # That would make the service tree go back only one step even if
            # user is clicking an earlier point in breadcrumbs.
            event.stopPropagation()
            @openService(event)

        openService: (event) ->
            $target = $(event.currentTarget)
            serviceId = $target.data('service-id')
            serviceName = $target.data('service-name')
            @animationType = $target.data('slide-direction')

            if not serviceId
                return null

            if serviceId == 'root'
                serviceId = null
                # Use splice to affect the original breadcrumbs array.
                @breadcrumbs.splice 0, @breadcrumbs.length
            else
                # See if the service is already in the breadcrumbs.
                index = _.indexOf(_.pluck(@breadcrumbs, 'serviceId'), serviceId)
                if index != -1
                    # Use splice to affect the original breadcrumbs array.
                    @breadcrumbs.splice index, @breadcrumbs.length - index
                @breadcrumbs.push(serviceId: serviceId, serviceName: serviceName)

            spinnerOptions =
                container: $target.get(0)
                hideContainerContent: true
            @collection.expand serviceId, spinnerOptions

        onRender: ->
            if @serviceToDisplay
                $targetElement = @$el.find("[data-service-id=#{@serviceToDisplay.id}]").find('.show-icon')
                @serviceToDisplay = false
                @toggleElement($targetElement)

            $ul = @$el.find('ul')
            $ul.on('scroll', (ev) =>
                @scrollPosition = ev.currentTarget.scrollTop)
            $ul.scrollTop(@scrollPosition)
            @scrollPosition = 0
            @setBreadcrumbWidths()

        setBreadcrumbWidths: ->
            CRUMB_MIN_WIDTH = 40
            # We need to use the last() jQuery method here, because at this
            # point the animations are still running and the DOM contains,
            # both the old and the new content. We only want to get the new
            # content and its breadcrumbs as a basis for our calculations.
            $container = @$el.find('.header-item').last()
            $crumbs = $container.find('.crumb')
            return unless $crumbs.length > 1

            # The last breadcrumb is given preference, so separate that from the
            # rest of the breadcrumbs.
            $lastCrumb = $crumbs.last()
            $crumbs = $crumbs.not(':last')

            $chevrons = $container.find('.icon-icon-forward')
            spaceAvailable = $container.width() - ($chevrons.length * $chevrons.first().outerWidth())
            lastWidth = $lastCrumb.width()
            spaceNeeded = lastWidth + $crumbs.length * CRUMB_MIN_WIDTH

            if spaceNeeded > spaceAvailable
                # Not enough space -> make the last breadcrumb narrower.
                lastWidth = spaceAvailable - $crumbs.length * CRUMB_MIN_WIDTH
                $lastCrumb.css('max-width': lastWidth)
                $crumbs.css('max-width': CRUMB_MIN_WIDTH)
            else
                # More space -> Make the other breadcrumbs wider.
                crumbWidth = (spaceAvailable - lastWidth) / $crumbs.length
                $crumbs.css('max-width': crumbWidth)

        selected: (serviceId) ->
            @selectedServices.get(serviceId)?
        close: ->
            @removeTooltip()
            @remove()
            @stopListening()

        serializeData: ->
            classes = (category) ->
                if category.get('children').length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            listItems = @collection.map (category) =>
                selected = @selected(category.id)

                rootId = category.get 'root'

                id: category.get 'id'
                name: category.getText 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: selected
                root_id: rootId
                show_icon_classes: @getShowIconClasses selected, rootId

            parentItem = {}
            back = null

            if @collection.chosenService
                back = @collection.chosenService.get('parent') or 'root'
                parentItem.name = @collection.chosenService.getText 'name'
                parentItem.rootId = @collection.chosenService.get 'root'

            data =
                back: back
                parent_item: parentItem
                list_items: listItems
                breadcrumbs: _.initial @breadcrumbs # everything but the last crumb

        onRender: ->
            $target = null
            if @collection.chosenService
                $target = @$el.find('li.service.parent.header-item')
            else
                $target = @$el.find('li.service').first()
            _.defer =>
                $target.focus()
