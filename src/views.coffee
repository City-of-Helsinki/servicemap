define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'TweenLite', 'app/p13n', 'app/widgets', 'app/jade', 'app/models', 'app/search', 'app/color'], (_, Backbone, Marionette, Leaflet, i18n, TweenLite, p13n, widgets, jade, models, search, colors) ->

    class SMItemView extends Marionette.ItemView
        templateHelpers:
            t: i18n.t
        getTemplate: ->
            return jade.get_template @template

    class SMLayout extends Marionette.Layout
        templateHelpers:
            t: i18n.t
        getTemplate: ->
            return jade.get_template @template

    class AppState extends Backbone.View
        initialize: (options)->
            @map_view = options.map_view
            @current_markers = {}
            @selected_services = options.selected_services
            @details_marker = null # The marker currently visible on details view.
            @all_markers = L.featureGroup()
            @listenTo app.vent, 'unit:render-one', @render_unit
            @listenTo app.vent, 'units:render-with-filter', @render_units_with_filter
            @listenTo app.vent, 'units:render-category', @render_units_by_category
        get_map: ->
            @map_view.map

        removeEmbeddedMapLoadingIndicator: -> app.vent.trigger 'embedded-map-loading-indicator:hide'

        render_unit: (id)->
            unit = new models.Unit id: id
            unit.fetch
                success: =>
                    unit_list = new models.UnitList [unit]
                    map.once 'zoomend', => @removeEmbeddedMapLoadingIndicator()
                    @draw_units unit_list, zoom: true, drawMarker: true
                    app.vent.trigger('unit_details:show', new models.Unit 'id': id)
                error: ->
                    @removeEmbeddedMapLoadingIndicator()
                    # TODO: decide where to route if route has invalid unit id.

        render_units_with_filter: (params)->
            queries = params.split('&')
            paramsArray = queries[0].split '=', 2

            needForTitleBar = -> _.contains(queries, 'tb')

            @unit_list = new models.UnitList()
            dataFilter = page_size: 1000
            dataFilter[paramsArray[0]] = paramsArray[1]
            @unit_list.fetch(
                data: dataFilter
                success: (collection)=>
                    @fetchAdministrativeDivisions(paramsArray[1], @findUniqueAdministrativeDivisions) if needForTitleBar()
                    map.once 'zoomend', => @removeEmbeddedMapLoadingIndicator()
                    @draw_units collection, zoom: true, drawMarker: true
                error: ->
                    @removeEmbeddedMapLoadingIndicator()
                    # TODO: what happens if no models are found with query?
            )

        render_units_by_category: (isSelected) ->
            publicCategories = [100, 101, 102, 103, 104]
            privateCategories = [105]

            onlyCategories = (categoriesArray) ->
                (model) -> _.contains categoriesArray, model.get('provider_type')

            publicUnits = @unit_list.filter onlyCategories publicCategories
            privateUnits = @unit_list.filter onlyCategories privateCategories
            unitsInCategory = []

            _.extend unitsInCategory, publicUnits if not isSelected.public
            _.extend unitsInCategory, privateUnits if not isSelected.private

            @draw_units(new models.UnitList unitsInCategory)

        fetchAdministrativeDivisions: (params, callback)->
            divisions = new models.AdministrativeDivisionList()
            divisions.fetch
                data: ocd_id: params
                success: callback

        findUniqueAdministrativeDivisions: (collection) ->
            byName = (division_model) -> division_model.toJSON().name
            divisionNames = collection.chain().map(byName).compact().unique().value()
            divisionNamesPartials = {}
            if divisionNames.length > 1
                divisionNamesPartials.start = _.initial(divisionNames).join(', ')
                divisionNamesPartials.end = _.last divisionNames
            else divisionNamesPartials.start = divisionNames[0]

            app.vent.trigger('administration-divisions-fetched', divisionNamesPartials)

        clear_all_markers: ->
            @all_markers.clearLayers()

        remember_markers: (service, markers) ->
            @current_markers[service.id] = markers

        remove_service_points: (service_id) ->
            _.each @current_markers[service_id], (marker) =>
                @get_map().removeLayer marker
            delete @current_markers[service_id]
            @selected_services.remove @selected_services.find (s) -> s.id == service_id
            @selected_services.trigger('change')

        add_service_points: (service, on_success, spinner_target = null) ->
            @selected_services.add service
            unit_list = new models.UnitList()
            unit_list.fetch
                data:
                    service: service.id
                    page_size: 1000
                    only: 'name,location'
                spinner_target: spinner_target
                success: =>
                    markers = @draw_units unit_list,
                        service: service
                    @remember_markers service, markers
                    @selected_services.trigger 'change'
                    on_success?()

        draw_units: (unit_list, opts) ->
            @clear_all_markers()
            markers = []

            unit_list.each (unit) =>
                color = colors.unit_color(unit, @selected_services) or 'rgb(255, 255, 255)'
                icon = new widgets.CanvasIcon 50, color
                location = unit.get('location')
                if location?
                    coords = location.coordinates
                    popup = L.popup(closeButton: false).setContent "<div class='unit-name'>#{unit.get_text 'name'}</div>"
                    marker = L.marker([coords[1], coords[0]], icon: icon)
                        .bindPopup(popup)

                    @all_markers.addLayer marker

                    marker.unit = unit
                    unit.marker = marker
                    markers.push marker
                    marker.on 'click', (event) =>
                        marker = event.target
                        @service_sidebar.show_details marker.unit
                        @details_marker?.closePopup()
                        popup.addTo(@get_map())
                        @details_marker = marker
                    marker.on 'mouseover', (event) ->
                        event.target.openPopup()

            _.each @current_markers, (markers, key, list) =>
                _.each markers, (marker) =>
                    @all_markers.addLayer marker

            @all_markers.addTo @get_map()
            bounds = L.latLngBounds (m.getLatLng() for m in markers)
            bounds = bounds.pad 0.05
            if opts? and opts.zoom
                @get_map().fitBounds @all_markers.getBounds()

            return markers

        # The transitions triggered by removing the class landing from body are defined
        # in the file landing-page.less.
        # When key animations have ended a 'landing-page-cleared' event is triggered.
        clear_landing_page: () ->
            if $('body').hasClass('landing')
                $('body').removeClass('landing')
                $('.service-sidebar').on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', (event) ->
                    if event.originalEvent.propertyName is 'top'
                        app.vent.trigger('landing-page-cleared')
                        $(@).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd')
                )

    class TitleView extends SMItemView
        className:
            'title-control'
        template:
            'title-view'

    class LandingTitleView extends Backbone.View
        id: 'title'
        className: 'landing-title-control'
        initialize: ->
            @listenTo(app.vent, 'title-view:hide', @hideTitleView)
            @listenTo(app.vent, 'title-view:show', @unHideTitleView)
        render: =>
            @el.innerHTML = jade.template 'landing-title-view', isHidden: @isHidden
        hideTitleView: ->
            $('body').removeClass 'landing'
            @isHidden = true
            @render()
        unHideTitleView: ->
            $('body').addClass 'landing'
            @isHidden = false
            @render()

    class TitleBarView extends Backbone.View
        events:
            'click a': 'preventDefault'
            'click .show-button': 'toggleShow'
            'click .panel-heading': 'collapseCategoryMenu'

        initialize: ->
            @listenTo(app.vent, 'administration-divisions-fetched', @render)
            @listenTo(app.vent, 'details_view:show', @hide)
            @listenTo(app.vent, 'details_view:hide', @show)

        render: (divisionNamePartials)->
            @el.innerHTML = jade.template 'embedded-title-bar', 'titleText': divisionNamePartials

        show: ->
            @delegateEvents
            @$el.removeClass 'hide'

        hide: ->
            @undelegateEvents()
            @$el.addClass 'hide'

        preventDefault: (ev) ->
            ev.preventDefault()

        toggleShow: (ev)->
            publicToggle = @$ '.public'
            privateToggle = @$ '.private'

            target = $(ev.target)
            target.toggleClass 'selected'

            isSelected =
                public: publicToggle.hasClass 'selected'
                private: privateToggle.hasClass 'selected'

            app.vent.trigger 'units:render-category', isSelected

        collapseCategoryMenu: ->
            @$('.panel-heading').toggleClass 'open'
            @$('.collapse').collapse 'toggle'

    class ServiceSidebarView extends Backbone.View
        tagName: 'div'
        className: 'service-sidebar'
        events:
            'typeahead:selected': 'autosuggest_show_details'
            'click .header': 'open'
            'click .close-button': 'close'

        initialize: (options) ->
            @parent = options.parent
            @selected_services = options.selected_services
            @service_tree_collection = options.service_tree_collection
            @listenTo app.vent, 'unit:render-one units:render-with-filter', @render
            # TODO: check why this was here
            #@listenTo app.vent, 'route:rootRoute', -> @render(notEmbedded: true)
            @listenTo app.vent, 'unit_details:show', @show_details

        open: (event) ->
            event.preventDefault()
            if @prevent_switch
                @prevent_switch = false
                return
            @parent.clear_landing_page()

            header_type = $(event.currentTarget).data('type')
            if header_type is 'search'
                @open_search()
            if header_type is 'browse'
                @open_service_tree()

        open_search: ->
            @$el.find('input').select()
            unless @$el.find('.container').hasClass('search-open')
                @update_classess('search')

        open_service_tree: ->
            unless @$el.find('.container').hasClass('browse-open')
                @update_classess('browse')

        close: (event) ->
            event.preventDefault()
            event.stopPropagation()

            header_type = $(event.target).closest('.header').data('type')
            @$el.find('.container').removeClass().addClass('container')
            @update_classess()

            # Clear search query if search is closed.
            if header_type is 'search'
                @$el.find('input').val('')

        update_classess: (opening) ->
            $container = @$el.find('.container')
            $container.removeClass().addClass('container')

            if opening is 'search'
                $container.addClass('search-open')
                @$el.find('.service-tree').css('max-height': 0)
            else if opening is 'browse'
                $container.addClass('browse-open')
                @service_tree.set_max_height()
            else
                @$el.find('.service-tree').css('max-height': 0)

        autosuggest_show_details: (ev, data, _) ->
            @prevent_switch = true
            if data.object_type == 'unit'
                @show_details new models.Unit(data),
                    zoom: true
                    draw_marker: true
            else if data.object_type == 'service'
                @open_service_tree()
                @service_tree.show_service(new models.Service(data))

        show_details: (unit, opts) ->
            if not opts
                opts = {}

            @$el.find('.container').addClass('details-open')
            @details_view.model = unit
            app.vent.trigger 'details_view:show'
            unit.fetch(success: =>
                @details_view.render()
            )
            if opts.draw_marker
                unit_list = new models.UnitList [unit]
                @parent.draw_units unit_list, opts

            # Set for console access
            window.debug_unit = unit

        hide_details: ->
            app.vent.trigger 'details_view:hide'
            @$el.find('.container').removeClass('details-open')

        enable_typeahead: (selector) ->
            @$el.find(selector).typeahead null,
                source: search.engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx

        render: (options)->
            s1 = i18n.t 'sidebar.search'
            if not s1
                console.log i18n
                throw 'i18n not initialized'

            isNotEmbeddedMap = ->
                true # todo: re-enable embedded version
                #if options? then !!options.notEmbedded else false

            isTitleBarShown = ->
                isTBParameterGiven = -> _.contains options.split('&'), 'tb'
                if options? and _.isString(options) then isTBParameterGiven() else false

            toggleEmbeddedClassAccordingToMapType = =>
                unless isNotEmbeddedMap()
                    @$el.addClass 'embedded'
                else
                    @$el.removeClass 'embedded'

            # todo: re-enable in a better way
            #toggleEmbeddedClassAccordingToMapType()
            templateOptions = showSearchBar: isNotEmbeddedMap(), showTitleBar: isTitleBarShown()
            template_string = jade.template 'service-sidebar', 'options': templateOptions

            @el.innerHTML = template_string
            @enable_typeahead('input.form-control[type=search]')

            @service_tree = new ServiceTreeView
                collection: @service_tree_collection
                selected_services: @selected_services
                app_view: @parent
                el: @$el.find('#service-tree-container')# if isNotEmbeddedMap()

            @details_view = new DetailsView
                el: @$el.find('#details-view-container')
                parent: @
                model: new models.Unit()
                embedded: !isNotEmbeddedMap()

            if isTitleBarShown()
                @title_bar_view = new TitleBarView el: @$el.find '#title-bar-container'

            return @el

    class DetailsView extends Backbone.View
        events:
            'click .back-button': 'close'
            'click .icon-icon-close': 'close'

        initialize: (options) ->
            @parent = options.parent
            @embedded = options.embedded

        close: (event) ->
            event.preventDefault()
            @parent.hide_details()

        set_max_height: () ->
            # Set the details view content max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.find('.content').offset().top
            @$el.find('.content').css 'max-height': max_height

        render: ->
            embedded = @embedded
            data = @model.toJSON()
            template_string = jade.template 'details', 'data': data, 'isEmbedded': embedded
            @el.innerHTML = template_string
            @set_max_height()

            return @el


    class ServiceTreeView extends Backbone.View
        events:
            'click .service.has-children': 'open'
            'click .service.parent': 'open'
            'click .service.leaf': 'toggle_leaf'
            'click .service .show-button': 'toggle_button'

        initialize: (options) ->
            @app_view = options.app_view
            @selected_services = options.selected_services
            @slide_direction = 'left'
            @scrollPosition = 0
            @listenTo @collection, 'sync', @render
            @listenTo @selected_services, 'change', ->
                @preventAnimation = true
                @render()
                @preventAnimation = false
            @collection.fetch
                data:
                    level: 0
            app.vent.on('landing-page-cleared', @set_max_height)

        category_url: (id) ->
            '/#/service/' + id

        toggle_leaf: (event) ->
            @toggle_element($(event.currentTarget).find('.show-button'))

        toggle_button: (event) ->
            event.preventDefault()
            event.stopPropagation()
            @toggle_element($(event.target))

        show_service: (service) =>
            @collection.expand service.attributes.parent
            @service_to_display = service

        get_show_button_classes: (showing, root_id) ->
            if showing
                return "show-button selected service-background-color-#{root_id}"
            else
                return "show-button service-hover-background-color-light-#{root_id}"

        toggle_element: ($target_element) ->
            service_id = $target_element.parent().data('service-id')
            root_id = $target_element.parent().data('root-id')
            unless @selected(service_id) is true
                service = new models.Service id: service_id
                service.fetch
                    success: =>
                        @app_view.add_service_points(service, null, $target_element.get(0))
                        #app.commands.execute 'addService', service
            else
                @app_view.remove_service_points(service_id)

        open: (event) ->
            $target = $(event.currentTarget)
            service_id = $target.data('service-id')
            @slide_direction = $target.data('slide-direction')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id, $target.get(0)

        set_max_height: () =>
            # Set the service tree max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.offset().top
            @$el.find('.service-tree').css 'max-height': max_height

        selected: (service_id) ->
            @selected_services.get(service_id)?

        render: ->
            classes = (category) ->
                if category.get('children').length > 0
                    return ['service has-children']
                else
                    return ['service leaf']

            list_items = @collection.map (category) =>
                selected = @selected(category.id)

                root_id = category.get 'root'
                show_button_classes = @get_show_button_classes selected, root_id

                id: category.get 'id'
                name: category.get_text 'name'
                classes: classes(category).join " "
                has_children: category.attributes.children.length > 0
                selected: selected
                root_id: root_id
                show_button_classes: show_button_classes

            parent_item = {}
            back = null

            if @collection.chosen_service
                back = @collection.chosen_service.get('parent') or 'root'
                parent_item.name = @collection.chosen_service.get_text 'name'
                parent_item.root_id = @collection.chosen_service.get 'root'

            data =
                back: back
                parent_item: parent_item
                list_items: list_items
            template_string = jade.template 'service-tree', data

            $old_content = @$el.find('ul')
            if !@preventAnimation and $old_content.length
                # Add content with sliding animation
                @$el.append $(template_string)
                $new_content = @$el.find('.new-content')

                # Calculate how much the new content needs to be moved.
                content_width = $new_content.width()
                content_margin = parseInt($new_content.css('margin-left').replace('px', ''))
                move_distance = content_width + content_margin

                if @slide_direction is 'left'
                    move_distance = "-=#{move_distance}px"
                else
                    move_distance = "+=#{move_distance}px"
                    # Move new content to the left side of the old content
                    $new_content.css 'left': -2 * (content_width + content_margin)

                TweenLite.to([$old_content, $new_content], 0.3, {
                    left: move_distance,
                    ease: Power2.easeOut,
                    onComplete: () ->
                        $old_content.remove()
                        $new_content.css 'left': 0
                        $new_content.removeClass('new-content')
                })
            else if @preventAnimation
                @el.innerHTML = template_string
            else
                # Don't use animations if there is no old content
                @$el.append $(template_string)

            if @service_to_display
                $target_element = @$el.find("[data-service-id=#{@service_to_display.id}]").find('.show-button')
                @service_to_display = false
                @toggle_element($target_element)

            @set_max_height()
            $ul = @$el.find('ul')
            $ul.on('scroll', (ev) =>
                @scrollPosition = ev.currentTarget.scrollTop)
            $ul.scrollTop(@scrollPosition)
            @scrollPosition = 0
            return @el

    class ServiceCart extends SMItemView
        events:
            'click .button.close-button': 'close_service'
        initialize: (opts) ->
            @app = opts.app
            @collection = opts.collection
            @collection.on 'change', @render
            @minimized = true
        close_service: (ev) ->
            @app.remove_service_points($(ev.currentTarget).data('service'))
        attributes: ->
            if not @minimized?
                @minimized = false
            {
                class: if @minimized then 'minimized' else 'expanded'
            }

        template: 'service-cart'
        tagName: 'ul'

    class CustomizationLayout extends SMLayout
        className: 'customization-container'
        template: 'customization-layout'
        regions:
            cart: '#service-cart'
            button_container: '#button-container'

    exports =
        AppState: AppState
        LandingTitleView: LandingTitleView
        TitleView: TitleView
        ServiceSidebarView: ServiceSidebarView
        ServiceTreeView: ServiceTreeView
        CustomizationLayout: CustomizationLayout
        ServiceCart: ServiceCart

    return exports
