define (require) ->
    _      = require 'underscore'
    i18n   = require 'i18next'

    p13n   = require 'cs!app/p13n'
    models = require 'cs!app/models'
    base   = require 'cs!app/views/base'

    class ServiceTreeView extends base.SMLayout
        id: 'service-tree-container'
        className: 'navigation-element'
        template: 'service-tree'
        events: ->
            openOnKbd = @keyboardHandler @openServiceNode, ['enter']
            toggleOnKbd = @keyboardHandler @toggleLeafButton, ['enter', 'space']
            'click .service-node.has-children': 'openServiceNode'
            'keydown .service-node.parent': openOnKbd
            'keydown .service-node.has-children': openOnKbd
            'keydown .service-node.has-children a.show-icon': toggleOnKbd
            'click .service-node.parent': 'openServiceNode'
            'click .collapse-button': 'openServiceNode'
            'click .crumb': 'handleBreadcrumbClick'
            'click .service-node.leaf': 'toggleLeaf'
            'keydown .service-node.leaf': toggleOnKbd
            'keydown .service-node .show-service-nodes-button': @keyboardHandler @toggleButton, ['enter', 'space']
            'click .service-node .show-service-nodes-button': 'toggleButton'
            'mouseenter .service-node .show-services-button': 'showTooltip'
            'mouseleave .service-node .show-services-button': 'removeTooltip'
            'keydown .service-tree .show-services ': @keyboardHandler @showServices, ['enter', 'space']
        type: 'service-tree'

        hideContents: ->
            @$el.find('.main-list').hide()

        showContents: ->
            @$el.find('.main-list').show()

        initialize: (options) ->
            @selectedServiceNodes = options.selectedServiceNodes
            @breadcrumbs = options.breadcrumbs
            @animationType = 'left'
            @scrollPosition = 0
            @listenTo @selectedServiceNodes, 'remove', (serviceNode, coll) =>
                if coll.isEmpty()
                    @render()
            @listenTo @selectedServiceNodes, 'add', @render
            @listenTo @selectedServiceNodes, 'reset', @render
            @listenTo p13n, 'city-change', @render

        toggleLeaf: (event) ->
            @toggleElement($(event.currentTarget).find('.show-badge-button'))
        toggleLeafButton: (event) ->
            @toggleElement $(event.currentTarget)

        toggleButton: (event) ->
            @removeTooltip()
            event.preventDefault()
            event.stopPropagation()
            @toggleElement($(event.target))
        
        showServices: (event) ->
            event.preventDefault()

            serviceNodeId = $(event.target.previousSibling).data('service-node-id')
            if !serviceNodeId?
                throw new Error "No service node id found from element data attributes"
                return

            app.request 'removeServiceNodes' # Remove old nodes
            #Add selected node to service nodes
            serviceNode = new models.ServiceNode id: serviceNodeId
            serviceNode.fetch
                success: =>
                    app.request 'addServiceNode', serviceNode, {}

        showTooltip: (event) ->
            tooltipContent = if ($ event.target).hasClass 'selected' then \
                "<div id=\"tooltip\">#{i18n.t('sidebar.hide_tooltip')}</div>" else \
                "<div id=\"tooltip\">#{i18n.t('sidebar.show_tooltip')}</div>"
            @removeTooltip()
            @$tooltipElement = $(tooltipContent)
            $targetEl = $(event.currentTarget)
            $('body').append @$tooltipElement
            buttonOffset = $targetEl.offset()
            originalOffset = @$tooltipElement.offset()
            @$tooltipElement.css 'top', "#{buttonOffset.top + originalOffset.top}px"
            @$tooltipElement.css 'left', "#{buttonOffset.left + originalOffset.left + 30}px"
        removeTooltip: (event) ->
            @$tooltipElement?.remove()

        getShowButtonClasses: (showing, rootId) ->
            if showing
                return "show-badge-button selected service-node-background-color-#{rootId}"
            else
                return "show-badge-button service-node-hover-background-color-light-#{rootId}"

        toggleElement: ($targetElement) ->
            serviceNodeId = $targetElement.closest('li').data('service-node-id')
            if @selected serviceNodeId
                app.request 'removeServiceNode', serviceNodeId
            else
                serviceNode = new models.ServiceNode id: serviceNodeId
                serviceNode.fetch
                    success: =>
                        app.request 'addServiceNode', serviceNode, {}

        handleBreadcrumbClick: (event) ->
            event.preventDefault()
            # We need to stop the event from bubling to the containing element.
            # That would make the service tree go back only one step even if
            # user is clicking an earlier point in breadcrumbs.
            event.stopPropagation()
            @openServiceNode(event)

        openServiceNode: (event) ->
            $target = $(event.currentTarget)
            serviceNodeId = $target.data('service-node-id')
            serviceNodeName = $target.data('service-node-name')
            @animationType = $target.data('slide-direction')

            # If the click goes to collapse-btn
            if $target.hasClass('collapse-button')
                @toggleCollapse(event)
                return false

            if not serviceNodeId
                return null

            if serviceNodeId == 'root'
                serviceNodeId = null
                # Use splice to affect the original breadcrumbs array.
                @breadcrumbs.splice 0, @breadcrumbs.length
            else
                # See if the serviceNode is already in the breadcrumbs.
                index = _.indexOf(_.pluck(@breadcrumbs, 'serviceNodeId'), serviceNodeId)
                if index != -1
                    # Use splice to affect the original breadcrumbs array.
                    @breadcrumbs.splice index, @breadcrumbs.length - index
                @breadcrumbs.push {serviceNodeId, serviceNodeName}

            spinnerOptions =
                container: $target.get(0)
                hideContainerContent: true
            @collection.expand serviceNodeId, spinnerOptions

        onDomRefresh: ->
            if @serviceNodeToDisplay
                $targetElement = @$el.find("[data-service-node-id=#{@serviceNodeToDisplay.id}]").find('.show-badge-button')
                @serviceNodeToDisplay = false
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

        selected: (serviceNodeId) ->
            @selectedServiceNodes.get(serviceNodeId)?
        close: ->
            @removeTooltip()
            @remove()
            @stopListening()

        serializeData: ->
            classes = (category) ->
                if category.get('children').length > 0
                    return ['service-node has-children']
                else
                    return ['service-node leaf']

            countUnits = (cities, category) ->
                unitCount = category.get('unit_count')
                if cities.length == 0
                    return unitCount.total
                else
                    filteredCities = _.pick unitCount.municipality, cities
                    return _.reduce _.values(filteredCities),
                        (memo, value) -> memo + value,
                        0

            cities = p13n.getCities()

            listItems = @collection.filter((c) => c.get('unit_count') != 0).map (category) =>
                selected = @selected(category.id)
                rootId = category.get 'root'

                id: category.get 'id'
                name: category.getText 'name'
                classes: classes(category).join " "
                has_children: category.get('children').length > 0
                count: countUnits cities, category
                selected: selected
                root_id: rootId
                show_button_classes: @getShowButtonClasses selected, rootId

            parentItem = {}
            back = null

            if @collection.chosenServiceNode
                back = @collection.chosenServiceNode.get('parent') or 'root'
                parentItem.name = @collection.chosenServiceNode.getText 'name'
                parentItem.rootId = @collection.chosenServiceNode.get 'root'

            data =
                collapsed: @collapsed || false
                back: back
                parent_item: parentItem
                list_items: listItems
                breadcrumbs: _.initial @breadcrumbs # everything but the last crumb
            data

        onDomRefresh: ->
            $target = null
            if @collection.chosenServiceNode
                $target = @$el.find('li.service-node.parent.header-item')
            else
                $target = @$el.find('li.service-node').first()
            _.defer =>
                $target
                .focus()
                .addClass('autofocus')
                .on 'blur', () ->
                    $target.removeClass('autofocus')
