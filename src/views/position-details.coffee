define (require) ->
    _              = require 'underscore'
    $              = require 'jquery'
    Backbone       = require 'backbone'
    moment         = require 'moment'

    models         = require 'cs!app/models'
    MapView        = require 'cs!app/map-view'
    base           = require 'cs!app/views/base'
    RouteView      = require 'cs!app/views/route'
    DetailsView    = require 'cs!app/views/details'
    {getIeVersion} = require 'cs!app/base'

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

    class PositionDetailsView extends DetailsView
        type: 'position'
        className: 'navigation-element limit-max-height'
        template: 'position'
        regions:
            'areaServices': '.area-services-placeholder'
            'areaEmergencyUnits': '#area-emergency-units-placeholder'
            'adminDivisions': '.admin-div-placeholder'
            'routeRegion': '.section.route-section'
        events:
            'click .icon-icon-close': 'selfDestruct'
            'click #reset-location': 'resetLocation'
            'click #add-circle': 'addCircle'
        isReady: ->
            @ready
        signalReady: ->
            @ready = true
            @trigger 'ready'
        initialize: (options) ->
            @ready = false
            super(options)
            _.extend(this.events, DetailsView.prototype.events);
            _.extend(this.regions, DetailsView.prototype.regions);
            @parent = options.parent
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
            coords = @model.get('location').coordinates
            deferreds = []
            @rescueUnits = {}
            deferreds.push @fetchDivisions(coords)
            for serviceId in EMERGENCY_UNIT_SERVICES
                coll = new models.UnitList()
                @rescueUnits[serviceId] = coll
                deferreds.push @fetchRescueUnits(coll, serviceId, coords)
            $.when(deferreds...).done =>
                @signalReady()
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
            unless coords? then return $.Deferred().resolve().promise()
            opts =
                data:
                    lon: coords[0]
                    lat: coords[1]
                    unit_include: UNIT_INCLUDE_FIELDS
                    type: (_.union SORTED_DIVISIONS, ['emergency_care_district']).join(',')
                    geometry: 'true'
                reset: true
            if appSettings.school_district_active_date?
                opts.data.date = moment(appSettings.school_district_active_date).format 'YYYY-MM-DD'
            @divList.fetch opts
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
            app.request 'resetPosition', @model

        addCircle: ->
            app.request 'setRadiusFilter', 750

        onDomRefresh: ->
            # Force this to fix scrolling issues with collapsing divs
            app.getRegion('navigation').currentView.updateMaxHeights()

        onShow: ->
            super()
            @renderAdminDivs()

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
                @areaEmergencyUnits?.show new EmergencyUnitLayout
                    rescueUnits: @rescueUnits
                @adminDivisions?.show new DivisionListView
                    collection: new models.AdministrativeDivisionList(
                        @divList.filter (d) => !@hiddenDivisions[d.get('type')]
                    )

        selfDestruct: (event) ->
            event.stopPropagation()
            app.request 'clearSelectedPosition'

    class DivisionListItemView extends base.SMItemView
        events:
            'click': 'handleClick'
        tagName: 'li'
        template: 'division-list-item'
        handleClick: =>
            app.request 'toggleDivision', @model
        initialize: =>
            @listenTo @model, 'change:selected', @render

    class DivisionListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'division-list sublist'
        childView: DivisionListItemView

    class EmergencyUnitLayout extends base.SMLayout
        tagName: 'div'
        className: 'emergency-units-wrapper'
        template: 'position-emergency-units'
        _regionName: (service) ->
            "service#{service}"
        initialize: ({rescueUnits: @rescueUnits}) =>
            for k, coll of @rescueUnits
                if coll.size() > 0
                    region = @addRegion(@_regionName(k), ".emergency-unit-service-#{k}")
        serializeData: ->
            _.object _.map(@rescueUnits, (coll, key) ->
                ['service' + key, coll.size() > 0])
        onShow: ->
            for k, coll of @rescueUnits
                continue if coll.size() < 1
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
            app.request 'setUnit', @model
            app.request 'selectUnit', @model, {}

    class UnitListView extends base.SMCollectionView
        tagName: 'ul'
        className: 'unit-list sublist'
        childView: UnitListItemView

    PositionDetailsView
