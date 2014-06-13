define 'app/views', ['underscore', 'backbone', 'backbone.marionette', 'leaflet', 'i18next', 'TweenLite', 'app/p13n', 'app/widgets', 'app/jade', 'app/models', 'app/search', 'app/color'], (_, Backbone, Marionette, Leaflet, i18n, TweenLite, p13n, widgets, jade, models, search, colors) ->

    PAGE_SIZE = 200
    MAX_AUTO_ZOOM = 12

    class SMItemView extends Marionette.ItemView
        templateHelpers:
            t: i18n.t
        getTemplate: ->
            return jade.get_template @template

    class SMCollectionView extends Marionette.CollectionView
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
            @mode = null # one of search, browse, null
            @selected_services = options.selected_services
            @details_marker = null # The marker currently visible on details view.
            @listenTo app.vent, 'unit:render-one', @render_unit
            @listenTo app.vent, 'units:render-with-filter', @render_units_with_filter
            @listenTo app.vent, 'units:render-category', @render_units_by_category
        map_markers: ->
            @map_view.all_markers
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
            dataFilter = page_size: PAGE_SIZE
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

        effective_horizontal_center: ->
            sidebar_edge = @service_sidebar.right_edge_coordinate()
            sidebar_edge + (@map_view.width() - sidebar_edge) / 2
        effective_center: ->
            [ Math.round(@effective_horizontal_center()),
              Math.round(@map_view.height() / 2) ]
        effective_padding_top_left: (pad) ->
            sidebar_edge = @service_sidebar.right_edge_coordinate()
            [sidebar_edge, pad]

        refit_bounds: (single) ->
            map = @get_map()
            marker_bounds = @map_markers().getBounds()
            if single or not map.getBounds().intersects marker_bounds
                opts =
                    paddingTopLeft: @effective_padding_top_left(100)
                    maxZoom: MAX_AUTO_ZOOM
                map.fitBounds marker_bounds, opts

        # The transitions triggered by removing the class landing from body are defined
        # in the file landing-page.less.
        # When key animations have ended a 'landing-page-cleared' event is triggered.
        clear_landing_page: () ->
            if $('body').hasClass('landing')
                $('body').removeClass('landing')
                $('.service-sidebar').on('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd', (event) ->
                    if not event.originalEvent
                        return
                    if event.originalEvent.propertyName is 'top'
                        app.vent.trigger('landing-page-cleared')
                        $(@).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd')
                )

    class TitleView extends SMItemView
        className:
            'title-control'
        render: =>
            @el.innerHTML = jade.template 'title-view', lang: p13n.get_language()

    class LandingTitleView extends Backbone.View
        id: 'title'
        className: 'landing-title-control'
        initialize: ->
            @listenTo(app.vent, 'title-view:hide', @hideTitleView)
            @listenTo(app.vent, 'title-view:show', @unHideTitleView)
        render: =>
            @el.innerHTML = jade.template 'landing-title-view', isHidden: @isHidden, lang: p13n.get_language()
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

    class BrowseButtonView extends SMItemView
        template: 'navigation-browse'
    class SearchInputView extends SMItemView
        classname: 'search-input-element'
        template: 'navigation-search'
        events:
            'typeahead:selected': 'autosuggest_show_details'
        onRender: () ->
            @enable_typeahead('input.form-control[type=search]')
        enable_typeahead: (selector) ->
            search_el = @$el.find selector
            search_el.typeahead null,
                source: search.engine.ttAdapter(),
                displayKey: (c) -> c.name[p13n.get_language()]
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> jade.template 'typeahead-suggestion', ctx

            # On enter: was there a selection from the autosuggestions
            # or did the user hit enter without having selected a
            # suggestion?
            selected = false
            search_el.on 'typeahead:selected', (ev) =>
                selected = true
            search_el.keyup (ev) =>
                # Handle enter
                if ev.keyCode != 13
                    return
                search_el.typeahead 'close'
                if selected
                    selected = false
                    return
                query = $.trim search_el.val()
                app.commands.execute 'search', query
            # TODO
            # search_el.on 'typeahead:opened', (ev) =>
            #     @search_results_view.hide()
        autosuggest_show_details: (ev, data, _) ->
            # todo: use SearchList and combine with
            # show_search_result below
            model = null
            @prevent_switch = true
            if data.object_type == 'unit'
                model = new models.Unit(data)
                app.commands.execute 'setUnit', model
            else if data.object_type == 'service'
                model = new models.Service(data)
            @show_search_result(model, null)
                # @show_details new models.Unit(data),
                #     zoom: true
                #     draw_marker: true

        show_search_result: (model, mode) ->
            if model == null
                return
            if model.get('object_type') == 'unit'
                app.commands.execute 'selectUnit', model
                # @show_details model,
                #     zoom: true
                #     draw_marker: true
            else if model.get('object_type') == 'service'
                app.commands.execute 'addService', model

    class NavigationHeaderView extends SMLayout
        # This view is responsible for rendering the navigation
        # header which allows the user to switch between searching
        # and browsing. Since the search bar is part of the header,
        # this view also handles search input.
        className: 'header-wrapper'
        template: 'navigation-header'
        regions:
            search: '#search-region'
            browse: '#browse-region'
        events:
            'click .header': 'open'
            'click .close-button': 'close'
        initialize: (options) ->
            @navigation_layout = options.layout
        onShow: ->
            @search.show new SearchInputView()
            @browse.show new BrowseButtonView()            
        open: (event) ->
            action_type = $(event.currentTarget).data('type')
            @update_classes action_type
            if action_type is 'search'
                @$el.find('input').select()
                @navigation_layout.change null
            else
                @navigation_layout.change action_type
        close: (event) ->
            event.preventDefault()
            event.stopPropagation()
            header_type = $(event.target).closest('.header').data('type')
            @update_classes null

            # Clear search query if search is closed.
            if header_type is 'search'
                @$el.find('input').val('')
            @navigation_layout.change()
        update_classes: (opening) ->
            classname = "#{opening}-open"
            if @$el.hasClass classname
                return
            @$el.removeClass().addClass('container')
            if opening?
                @$el.addClass classname

    class NavigationLayout extends SMLayout
        className: 'service-sidebar' # todo: rename
        template: 'navigation-layout'
        regions:
            header: '#navigation-header'
            contents: '#navigation-contents'
        onShow: ->
            @header.show new NavigationHeaderView
                layout: this
        initialize: (options) ->
            @service_tree_collection = options.service_tree_collection
            @selected_services = options.selected_services
            @search_results = options.search_results
            @selected_units = options.selected_units
            @add_listeners()
        add_listeners: ->
            @listenTo @search_results, 'reset', ->
                @change('search')
            @listenTo @selected_units, 'reset', (coll, opts) ->
                if coll.isEmpty()
                    @change()
                else
                    @change 'details'
            @listenTo @selected_units, ''
        change: (type) ->
            switch type
                when 'browse'
                    view = new ServiceTreeView
                        collection: @service_tree_collection
                        selected_services: @selected_services
                when 'search'
                    view = new SearchResultsView
                        collection: @search_results
                when 'details'
                    view = new DetailsView
                        collection: @selected_units
                else
                    @contents.reset()

            if view?
                # todo: animations
                @contents.show view
                if type == 'browse'
                    # downwards reveal anim
                    # todo: upwards hide
                    view.set_max_height(0)
                    view.set_max_height()

    class DetailsView extends SMItemView
        # This view's collection is the selected unit list
        # of length 1.
        id:
            'details-view-container'
        events:
            'click .back-button': 'user_close'
            'click .icon-icon-close': 'user_close'

        initialize: (options) ->
            @parent = options.parent
            @embedded = options.embedded
            @listenTo @collection, 'reset', @render

        user_close: (event) ->
            @collection.reset []

        set_max_height: () ->
            # Set the details view content max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.find('.content').offset().top
            @$el.find('.content').css 'max-height': max_height

        render: ->
            if @collection.isEmpty()
                return @el
            embedded = @embedded
            data = @collection.first().toJSON()
            description = data.description
            data.back_to = null
            # todo
            # if @parent.mode()?
            #     data.back_to = i18n.t('sidebar.back_to.' + @parent.mode())
            MAX_LENGTH = 20
            if description
                words = description.split /[ ]+/
                if words.length > MAX_LENGTH + 1
                    data.description = words[0..MAX_LENGTH].join(' ') + '&hellip;'
            data.embedded_mode = embedded
            template_string = jade.template 'details', data
            @el.innerHTML = template_string
            @set_max_height()

            return @el


    class ServiceTreeView extends Backbone.View
        id:
            'service-tree-container'
        events:
            'click .service.has-children': 'open'
            'click .service.parent': 'open'
            'click .service.leaf': 'toggle_leaf'
            'click .service .show-button': 'toggle_button'

        initialize: (options) ->
            @selected_services = options.selected_services
            @slide_direction = 'left'
            @scrollPosition = 0
            @listenTo @collection, 'sync', @render
            callback =  ->
                @preventAnimation = true
                @render()
                @preventAnimation = false
            @listenTo @selected_services, 'remove', callback
            @listenTo @selected_services, 'add', callback
            @listenTo @selected_services, 'reset', callback

        toggle_leaf: (event) ->
            @toggle_element($(event.currentTarget).find('.show-button'))

        toggle_button: (event) ->
            event.preventDefault()
            event.stopPropagation()
            @toggle_element($(event.target))

        get_show_button_classes: (showing, root_id) ->
            if showing
                return "show-button selected service-background-color-#{root_id}"
            else
                return "show-button service-hover-background-color-light-#{root_id}"

        toggle_element: ($target_element) ->
            service_id = $target_element.parent().data('service-id')
            unless @selected(service_id) is true
                service = new models.Service id: service_id
                service.fetch
                    success: =>
                        app.commands.execute 'addService', service
            else
                app.commands.execute 'removeService', service_id

        open: (event) ->
            $target = $(event.currentTarget)
            service_id = $target.data('service-id')
            @slide_direction = $target.data('slide-direction')
            if not service_id
                return null
            if service_id == 'root'
                service_id = null
            @collection.expand service_id, $target.get(0)

        set_max_height: (height) =>
            if height?
                max_height = height
            else
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

            $ul = @$el.find('ul')
            $ul.on('scroll', (ev) =>
                @scrollPosition = ev.currentTarget.scrollTop)
            $ul.scrollTop(@scrollPosition)
            @scrollPosition = 0
            return @el

    class SearchResultView extends SMItemView
        tagName: 'li'
        events:
            'click': 'select_result'
            'mouseenter': 'highlight_result'
        template: 'search-result'
        initialize: (opts) ->
            @parent = opts.parent
            @collection_view = opts.collection_view
        select_result: (ev) ->
            app.commands.execute 'selectUnit', @model
        highlight_result: (ev) ->
            @model.marker?.openPopup()

    class SearchResultsView extends SMCollectionView
        tagName: 'ul'
        className: 'search-results'
        itemView: SearchResultView
        itemViewOptions: (model, index) ->
            parent: @parent
            collection_view: @
        initialize: (opts) ->
            @parent = opts.parent
        reset: ->
            @collection?.reset()
            @render()
        hide: ->
            @$el.hide()
        show: ->
            @$el.show()
            @set_max_height()
        set_max_height: () =>
            # Set the service tree max height for proper scrolling.
            max_height = $(window).innerHeight() - @$el.offset().top
            @$el.css 'max-height': max_height

    class ServiceCart extends SMItemView
        events:
            'click .button.close-button': 'close_service'
        initialize: (opts) ->
            @app = opts.app
            @collection = opts.collection
            @listenTo @collection, 'add', @render
            @listenTo @collection, 'remove', @render
            @listenTo @collection, 'reset', @render
            @minimized = true
        close_service: (ev) ->
            app.commands.execute 'removeService', $(ev.currentTarget).data('service')
        attributes: ->
                class: if @minimized then 'minimized' else 'expanded'

        template: 'service-cart'
        tagName: 'ul'

    class LanguageSelectorView extends SMItemView
        template: 'language-selector'
        events:
            'click .language': 'select_language'
        initialize: (opts) ->
            @p13n = opts.p13n
            @languages = @p13n.supported_languages()
            @refresh_collection()
        select_language: (ev) ->
            l = $(ev.currentTarget).data('language')
            @p13n.set_language(l)
            window.location.reload()
        refresh_collection: ->
            selected = @p13n.get_language()
            language_models = _.map @languages, (l) ->
                new models.Language
                    code: l.code
                    name: l.name
                    selected: l.code == selected
            @collection = new models.LanguageList _.filter language_models, (l) -> !l.get('selected')

    class CustomizationLayout extends SMLayout
        className: 'customization-container'
        template: 'customization-layout'
        regions:
            language: '#language-selector'
            cart: '#service-cart'
            button_container: '#button-container'

    exports =
        AppState: AppState
        LandingTitleView: LandingTitleView
        TitleView: TitleView
        ServiceTreeView: ServiceTreeView
        CustomizationLayout: CustomizationLayout
        ServiceCart: ServiceCart
        LanguageSelectorView: LanguageSelectorView
        NavigationLayout: NavigationLayout

    return exports
