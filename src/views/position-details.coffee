define [
    'underscore',
    'jquery',
    'backbone',
    'cs!app/models',
    'cs!app/map-view',
    'cs!app/views/base',
    'cs!app/views/route',
    'cs!app/base'
], (
    _,
    $,
    Backbone,
    models,
    MapView,
    base,
    RouteView,
    {getIeVersion: getIeVersion}
) ->
    UNIT_INCLUDE_FIELDS = 'name,root_services,location,street_address'
    SORTED_DIVISIONS = [
        'postcode_area',
        'neighborhood',
        'health_station_district',
        'maternity_clinic_district',
        'income_support_district',
        'lower_comprehensive_school_district_fi',
        'lower_comprehensive_school_district_sv',
        'upper_comprehensive_school_district_fi',
        'upper_comprehensive_school_district_sv',
        'rescue_area',
        'rescue_district',
        'rescue_sub_district',
    ]
    # the following ids represent
    # rescue related service points
    # such as emergency shelters
    EMERGENCY_UNIT_SERVICES = [26214, 26210, 26208]

    class PositionDetailsView extends base.SMLayout
        type: 'position'
        id: 'details-view-container'
        className: 'navigation-element limit-max-height'
        template: 'position'
        regions:
            'areaServices': '.area-services-placeholder'
            'areaEmergencyUnits': '#area-emergency-units-placeholder'
            'adminDivisions': '.admin-div-placeholder'
            'routeRegion': '.section.route-section'
        events:
            'click .map-active-area': 'showMap'
            'click .mobile-header': 'showContent'
            'click .icon-icon-close': 'selfDestruct'
            'click .collapse-button': 'toggleCollapse'
            'click #reset-location': 'resetLocation'
            'click #add-circle': 'addCircle'
            'show.bs.collapse': 'scrollToExpandedSection'
            'hide.bs.collapse': '_removeLocationHash'
        initialize: (options) ->
            @selectedPosition = options.selectedPosition
            @route = options.route
            @parent = options.parent
            @routingParameters = options.routingParameters
            @hiddenDivisions =
                emergency_care_district: true

            @divList = new models.AdministrativeDivisionList()
            @listenTo @model, 'reverse-geocode', =>
                @fetchDivisions().done =>
                    @render()
            @divList.comparator = (a, b) =>
                indexA = _.indexOf SORTED_DIVISIONS, a.get('type')
                indexB = _.indexOf SORTED_DIVISIONS, b.get('type')
                if indexA < indexB then return -1
                if indexB < indexA then return 1
                if indexA == indexB
                    as = a.get('start')
                    ae = a.get('end')
                    bs = b.get('start')
                    unless as or ae then return 0
                    if as
                        unless bs then return 1
                        if as < bs then return -1
                        else return 1
                    else
                        if bs then return -1
                        else return 0
                return 0
            @listenTo @divList, 'reset', @renderAdminDivs
            coords = @model.get('location').coordinates
            deferreds = []
            @rescueUnits = {}
            deferreds.push @fetchDivisions(coords)
            for serviceId in EMERGENCY_UNIT_SERVICES
                coll = new models.UnitList()
                @rescueUnits[serviceId] = coll
                deferreds.push @fetchRescueUnits(coll, serviceId, coords)
            $.when(deferreds...).done =>
                @render()
        fetchRescueUnits: (coll, sid, coords) ->
            coll.pageSize = 5
            distance = 1000
            if sid == 26214
                coll.pageSize = 1
                distance = 5000
            coll.fetch
                data:
                    service: "#{sid}"
                    lon: coords[0]
                    lat: coords[1]
                    distance: distance
                    include: "#{UNIT_INCLUDE_FIELDS},services"
        fetchDivisions: (coords) ->
            @divList.fetch
                data:
                    lon: coords[0]
                    lat: coords[1]
                    unit_include: UNIT_INCLUDE_FIELDS
                    type: (_.union SORTED_DIVISIONS, ['emergency_care_district']).join(',')
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
            data.collapsed = @collapsed
            data

        resetLocation: ->
            app.commands.execute 'resetPosition', @model

        addCircle: ->
            app.commands.execute 'setRadiusFilter', 750

        onRender: ->
            @routeRegion.show new RouteView
                model: @model
                route: @route
                parentView: @
                routingParameters: @routingParameters
                selectedUnits: null
                selectedPosition: @selectedPosition
            @renderAdminDivs()
            @listenTo app.vent, 'hashpanel:render', (hash) -> @_triggerPanel(hash)
        renderAdminDivs: ->
            divsWithUnits = @divList.filter (x) -> x.has('unit')
            emergencyDiv = @divList.find (x) ->
                x.get('type') == 'emergency_care_district'
            if divsWithUnits.length > 0
                units = new Backbone.Collection(
                    divsWithUnits.map (x) ->
                        # Ugly hack to allow duplicate
                        # units in listing.
                        unit = new models.Unit x.get('unit')
                        unitData = unit.attributes
                        storedId = unitData.id
                        delete unitData.id
                        unitData.storedId = storedId
                        unitData.area = x
                        if x.get('type') == 'health_station_district'
                            unitData.emergencyUnitId = emergencyDiv.getEmergencyCareUnit()
                        new Backbone.Model(unitData)
                )
                @areaServices.show new UnitListView
                    collection: units
                @areaEmergencyUnits.show new EmergencyUnitLayout
                    rescueUnits: @rescueUnits
                @adminDivisions.show new DivisionListView
                    collection: new models.AdministrativeDivisionList(
                        @divList.filter (d) => !@hiddenDivisions[d.get('type')]
                    )
        scrollToExpandedSection: (event) ->
            $container = @$el.find('.content').first()
            $target = $(event.target)
            @_setLocationHash($target)

            # Don't scroll if route leg is expanded.
            return if $target.hasClass('steps')
            $section = $target.closest('.section')
            scrollTo = $container.scrollTop() + $section.position().top
            $('#details-view-container .content').animate(scrollTop: scrollTo)
        showMap: (event) ->
            event.preventDefault()
            @$el.addClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: true
        showContent: (event) ->
            event.preventDefault()
            @$el.removeClass 'minimized'
            MapView.setMapActiveAreaMaxHeight maximize: false

        _removeLocationHash: (event) ->
            window.location.hash = '' unless @_checkIEversion()

        _setLocationHash: (target) ->
            window.location.hash = '!' + target.attr('id') unless @_checkIEversion()

        _checkIEversion: () ->
            getIeVersion() and getIeVersion() < 10

        _triggerPanel: (hash) ->
            _.defer =>
                triggerElem = $("a[href='" + hash + "']")
                triggerElem.trigger('click').attr('tabindex', -1).focus()

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

    class EmergencyUnitLayout extends base.SMLayout
        tagName: 'div'
        className: 'emergency-units-wrapper'
        template: 'position-emergency-units'
        _regionName: (service) ->
            "service#{service}"
        initialize: (rescueUnits: @rescueUnits) =>
            for k, coll of @rescueUnits
                region = @addRegion(@_regionName(k), ".emergency-unit-service-#{k}")
        serializeData: ->
            _.object _.map(@rescueUnits, (coll, key) ->
                ['service' + key, coll.size() > 0])
        onRender: ->
            for k, coll of @rescueUnits
                view = new UnitListView collection: coll
                @getRegion(@_regionName(k)).show view

    class UnitListItemView extends base.SMItemView
        events:
            'click #emergency-unit-notice a': 'handleInnerClick'
            'click': 'handleClick'
        tagName: 'li'
        template: 'unit-list-item'
        serializeData: ->
            unless @model.get('storedId')
                return super()
            data = @model.toJSON()
            data.id = @model.get 'storedId'
            @model = new models.Unit(data)
            data = super()
            data.start = data.area.get('start')
            data.end = data.area.get('end')
            return data
        handleInnerClick: (ev) =>
            ev?.stopPropagation()
        handleClick: (ev) =>
            ev?.preventDefault()
            app.commands.execute 'setUnit', @model
            app.commands.execute 'selectUnit', @model

    class UnitListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'unit-list sublist'
        itemView: UnitListItemView



    PositionDetailsView
