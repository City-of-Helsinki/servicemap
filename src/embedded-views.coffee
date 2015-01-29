define [
    'app/views',
    'backbone'
], (
    views,
    Backbone
) ->

    class EmbeddedMap extends Backbone.View
        # Todo: re-enable functionality
        initialize: (options)->
            @map_view = options.map_view
            @map = @map_view.get_map()
            @listenTo app.vent, 'unit:render-one', @render_unit
            @listenTo app.vent, 'units:render-with-filter', @render_units_with_filter
            @listenTo app.vent, 'units:render-category', @render_units_by_category

        removeEmbeddedMapLoadingIndicator: -> app.vent.trigger 'embedded-map-loading-indicator:hide'

        render_unit: (id)->
            unit = new models.Unit id: id
            unit.fetch
                success: =>
                    unit_list = new models.UnitList [unit]
                    @map.once 'zoomend', => @removeEmbeddedMapLoadingIndicator()
                    @map_view.draw_units unit_list, zoom: true, drawMarker: true
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
                    @map.once 'zoomend', => @removeEmbeddedMapLoadingIndicator()
                    @map_view.draw_units collection, zoom: true, drawMarker: true
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

            @map_view.draw_units(new models.UnitList unitsInCategory)

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

    class TitleBarView extends views.SMItemView
        template: 'embedded-title-bar'
        events:
            'click a': 'preventDefault'
            'click .show-button': 'toggleShow'
            'click .panel-heading': 'collapseCategoryMenu'

        initialize: ->
            @listenTo(app.vent, 'administration-divisions-fetched', @receiveData)
            @listenTo(app.vent, 'details_view:show', @hide)
            @listenTo(app.vent, 'details_view:hide', @show)

        receiveData: (divisionNamePartials) ->
            @divisionNamePartials = divisionNamePartials
        serializeData:
            titleText: @divisionNamePartials
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

    return EmbeddedMap
