define [
    'underscore',
    'cs!app/models',
    'cs!app/map-view',
    'cs!app/views/base',
    'cs!app/views/route'
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
            'areaServices': '.area-services-placeholder'
            'adminDivisions': '.admin-div-placeholder'
            'routeRegion': '.section.route-section'
        events:
            'click .map-active-area': 'showMap'
            'click .mobile-header': 'showContent'
            'click .icon-icon-close': 'selfDestruct'
            'click #reset-location': 'resetLocation'
            'click #add-circle': 'addCircle'
        initialize: (options) ->
            @selectedPosition = options.selectedPosition
            @route = options.route
            @parent = options.parent
            @routingParameters = options.routingParameters
            @sortedDivisions = [
                'postcode_area',
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

            @divList = new models.AdministrativeDivisionList()
            @listenTo @model, 'reverse-geocode', =>
                @fetchDivisions().done =>
                    @render()
            @divList.comparator = (a, b) =>
                indexA = _.indexOf @sortedDivisions, a.get('type')
                indexB = _.indexOf @sortedDivisions, b.get('type')
                if indexA < indexB then return -1
                if indexB < indexA then return 1
                return 0
            @listenTo @divList, 'reset', @renderAdminDivs
            @fetchDivisions().done =>
                @render()
        fetchDivisions: ->
            coords = @model.get('location').coordinates
            @divList.fetch
                data:
                    lon: coords[0]
                    lat: coords[1]
                    unit_include: 'name,root_services,location'
                    type: (_.union @sortedDivisions, ['emergency_care_district']).join(',')
                    geometry: 'true'
                reset: true
        serializeData: ->
            data = super()
            data.icon_class = switch @model.origin()
                when 'address' then 'icon-icon-address'
                when 'detected' then 'icon-icon-you-are-here'
                when 'clicked' then 'icon-icon-address'
            data.origin = @model.origin()
            data.neighborhood = @divList.findWhere type: 'neighborhood'
            data.postcode = @divList.findWhere type: 'postcode_area'
            data.name = @model.humanAddress()
            data

        resetLocation: ->
            app.commands.execute 'resetPosition', @model

        addCircle: ->
            app.commands.execute 'setRadiusFilter', 750

        onRender: ->
            @renderAdminDivs()
            @routeRegion.show new RouteView
                model: @model
                route: @route
                parentView: @
                routingParameters: @routingParameters
                selectedUnits: null
                selectedPosition: @selectedPosition
        renderAdminDivs: ->
            divsWithUnits = @divList.filter (x) -> x.has('unit')
            emergencyDiv = @divList.find (x) ->
                x.get('type') == 'emergency_care_district'
            if divsWithUnits.length > 0
                units = new models.UnitList(
                    divsWithUnits.map (x) ->
                        unit = new models.Unit x.get('unit')
                        unit.set 'area', x
                        if x.get('type') == 'health_station_district'
                            unit.set 'emergencyUnitId', emergencyDiv.getEmergencyCareUnit()
                        unit
                )
                @areaServices.show new UnitListView
                    collection: units
                @adminDivisions.show new DivisionListView
                    collection: new models.AdministrativeDivisionList(@divList.filter (x) => x.get('type') != 'emergency_care_district')
        showMap: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: true
        showContent: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: false

        selfDestruct: (event) ->
            event.stopPropagation()
            app.commands.execute 'clearSelectedPosition'

    class DivisionListItemView extends base.SMItemView
        events:
            'click': 'handleClick'
        tagName: 'li'
        template: 'division-list-item'
        handleClick: =>
            app.commands.execute 'toggleDivision', @model
        initialize: =>
            @listenTo @model, 'change:selected', @render

    class DivisionListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'division-list sublist'
        itemView: DivisionListItemView


    class UnitListItemView extends base.SMItemView
        events:
            'click a': 'handleInnerClick'
            'click': 'handleClick'
        tagName: 'li'
        template: 'unit-list-item'
        serializeData: ->
            data = super()
            data
        handleInnerClick: (ev) =>
            ev?.preventDefault()
        handleClick: (ev) =>
            ev?.preventDefault()
            app.commands.execute 'setUnit', @model
            app.commands.execute 'selectUnit', @model

    class UnitListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'unit-list sublist'
        itemView: UnitListItemView



    PositionDetailsView
