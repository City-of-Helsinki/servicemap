define [
    'underscore',
    'app/models',
    'app/map-view',
    'app/views/base',
    'app/views/route'
], (
    _,
    models,
    MapView,
    base,
    RouteView
) ->

    class PositionDetailsView extends base.SMLayout
        type: 'position'
        id: 'details-view-container'
        className: 'navigation-element limit-max-height'
        template: 'position'
        regions:
            'area_services': '.area-services-placeholder'
            'admin_divisions': '.admin-div-placeholder'
            'route_region': '.section.route-section'
        events:
            'click .map-active-area': 'show_map'
            'click .mobile-header': 'show_content'
            'click .icon-icon-close': 'self_destruct'
        initialize: (options) ->
            @selected_position = options.selected_position
            @user_click_coordinate_position = options.user_click_coordinate_position
            @route = options.route
            @parent = options.parent
            @routing_parameters = options.routing_parameters
            @sorted_divisions = [
                'neighborhood',
                'rescue_district',
                'health_station_district',
                'maternity_clinic_district',
                'income_support_district',
                'lower_comprehensive_school_district_fi',
                'lower_comprehensive_school_district_sv',
                'upper_comprehensive_school_district_fi',
                'upper_comprehensive_school_district_sv'
                ]

            @div_list = new models.AdministrativeDivisionList()
            @listenTo @model, 'reverse_geocode', =>
                @fetch_divisions().done =>
                    @render()
            @div_list.comparator = (a, b) =>
                index_a = _.indexOf @sorted_divisions, a.get('type')
                index_b = _.indexOf @sorted_divisions, b.get('type')
                if index_a < index_b then return -1
                if index_b < index_a then return 1
                return 0
            @listenTo @div_list, 'reset', @render_admin_divs
            @fetch_divisions().done =>
                @render()
        fetch_divisions: ->
            coords = @model.get('location').coordinates
            @div_list.fetch
                data:
                    lon: coords[0]
                    lat: coords[1]
                    unit_include: 'name,root_services,location'
                    type: @sorted_divisions.join(',')
                    geometry: 'false'
                reset: true
        serializeData: ->
            data = super()
            data.icon_class = switch @model.origin()
                when 'address' then 'icon-icon-address'
                when 'detected' then 'icon-icon-you-are-here'
                when 'clicked' then 'icon-icon-address'
            data.origin = @model.origin()
            data.neighborhood = @div_list.findWhere type: 'neighborhood'
            data
        onRender: ->
            @render_admin_divs()
            @route_region.show new RouteView
                model: @model
                route: @route
                parent_view: @
                routing_parameters: @routing_parameters
                user_click_coordinate_position: @user_click_coordinate_position
                selected_units: null
                selected_position: @selected_position
        render_admin_divs: ->
            divs_with_units = @div_list.filter (x) -> x.has('unit')
            if divs_with_units.length > 0
                units = new models.UnitList(
                    divs_with_units.map (x) ->
                        unit = new models.Unit x.get('unit')
                        unit.set 'area', x
                        unit
                )
                @area_services.show new UnitListView
                    collection: units
                @admin_divisions.show new DivisionListView
                    collection: @div_list
        show_map: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.set_map_active_area_max_height maximize: true
        show_content: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.set_map_active_area_max_height maximize: false

        self_destruct: (event) ->
            event.stopPropagation()
            @selected_position.clear()


    class DivisionListItemView extends base.SMItemView
        events:
            'click': 'handle_click'
        tagName: 'li'
        template: 'division-list-item'
        handle_click: =>
            @model

    class DivisionListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'division-list sublist'
        itemView: DivisionListItemView


    class UnitListItemView extends base.SMItemView
        events:
            'click': 'handle_click'
        tagName: 'li'
        template: 'unit-list-item'
        handle_click: (ev) =>
            ev?.preventDefault()
            app.commands.execute 'setUnit', @model
            app.commands.execute 'selectUnit', @model

    class UnitListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'unit-list sublist'
        itemView: UnitListItemView



    PositionDetailsView
