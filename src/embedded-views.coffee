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
        className: 'panel panel-default'
        events:
            'click a': 'preventDefault'
            'click .show-button': 'toggleShow'
            'click .panel-heading': 'collapseCategoryMenu'

        initialize: (@model) ->
            @listenTo @model, 'sync', @render

        division_names: (divisions) =>
            divisions.pluck 'name'

        serializeData: ->
            divisions: @division_names @model
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
            $('.panel-heading').toggleClass 'open'
            #$('.collapse').collapse 'toggle'

    return TitleBarView
