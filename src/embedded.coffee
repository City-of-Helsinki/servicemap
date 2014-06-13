define 'app/embedded', () ->

    class EmbeddedMap extends Backbone.View
        # Todo: re-enable functionality
        initialize: (options)->
            @mode = null # one of search, browse, null
            @details_marker = null # The marker currently visible on details view.
            @listenTo app.vent, 'unit:render-one', @render_unit
            @listenTo app.vent, 'units:render-with-filter', @render_units_with_filter
            @listenTo app.vent, 'units:render-category', @render_units_by_category

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
    
    return EmbeddedMap
