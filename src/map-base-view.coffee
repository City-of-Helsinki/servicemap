define (require) ->
    Backbone         = require 'backbone'
    Marionette       = require 'backbone.marionette'
    i18n             = require 'i18next'
    L                = require 'leaflet'
    markercluster    = require 'leaflet.markercluster'
    leaflet_snogylop = require 'leaflet.snogylop'

    map              = require 'cs!app/map'
    widgets          = require 'cs!app/widgets'
    jade             = require 'cs!app/jade'
    MapStateModel    = require 'cs!app/map-state-model'
    dataviz          = require 'cs!app/data-visualization'
    {getIeVersion}   = require 'cs!app/base'

    # TODO: remove duplicates
    MARKER_POINT_VARIANT = false
    DEFAULT_CENTER =
        helsinki: [60.171944, 24.941389]
        espoo: [60.19792, 24.708885]
        vantaa: [60.309045, 25.004675]
        kauniainen: [60.21174, 24.729595]
    ICON_SIZE = 40

    if getIeVersion() and getIeVersion() < 9
        ICON_SIZE *= .8

    L.extend L.LatLng, MAX_MARGIN: 1.0e-7

    class MapBaseView extends Backbone.Marionette.View
        @WORLD_LAT_LNGS: [
            L.latLng([64, 32]),
            L.latLng([64, 21]),
            L.latLng([58, 21]),
            L.latLng([58, 32])
        ]
        getIconSize: ->
            ICON_SIZE
        initialize: ({@opts, @mapOpts, @embedded}) ->
            @markers = {}
            @geometries = {}
            @units = @opts.units
            @selectedUnits = @opts.selectedUnits
            @selectedPosition = @opts.selectedPosition
            @divisions = @opts.divisions
            @statistics = @opts.statistics
            @listenTo @units, 'reset', @drawUnits
            @listenTo p13n, 'accessibility-change', => @updateMarkers(@units)
            @listenTo @units, 'finished', (options) =>
                # Triggered when all of the
                # pages of units have been fetched.
                @drawUnits @units, options
                if @selectedUnits.isSet()
                    @highlightSelectedUnit @selectedUnits.first()

        getProxy: ->
            fn = => map.MapUtils.overlappingBoundingBoxes @map
            getTransformedBounds: fn

        mapOptions: {}

        render: ->
            @$el.attr 'id', 'map'

        getMapStateModel: ->
            new MapStateModel @opts, @embedded

        onShow: ->
            # The map is created only after the element is added
            # to the DOM to work around Leaflet init issues.
            mapStyle = p13n.get 'map_background_layer'
            options =
                style: mapStyle
                language: p13n.getLanguage()
            @map = map.MapMaker.createMap @$el.get(0), options, @mapOptions, @getMapStateModel()
            @map.on 'click', _.bind(@onMapClicked, @)
            @allMarkers = @getFeatureGroup()
            @allMarkers.addTo @map
            @allGeometries = L.featureGroup()
            @allGeometries.addTo @map
            @divisionLayer = L.featureGroup()
            @divisionLayer.addTo @map
            @visualizationLayer = L.featureGroup()
            @visualizationLayer.addTo @map
            @postInitialize()

        onMapClicked: (ev) -> # override

        calculateInitialOptions: ->
            city = p13n.getCity()
            unless city?
                city = 'helsinki'
            center = DEFAULT_CENTER[city]
            # Default state without selections
            defaults =
                zoom: if (p13n.get('map_background_layer') == 'servicemap') then 10 else 5
                center: center
            if @selectedPosition.isSet()
                zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
                center: map.MapUtils.latLngFromGeojson @selectedPosition.value()
            else if @selectedUnits.isSet()
                unit = @selectedUnits.first()
                if unit.get('location')?
                    zoom: @getMaxAutoZoom()
                    center: map.MapUtils.latLngFromGeojson(unit)
                else
                    return defaults
            else if @divisions.isSet()
                boundaries = @divisions.map (d) =>
                    new L.GeoJSON d.get('boundary')
                iteratee = (memo, value) => memo.extend value.getBounds()
                bounds = _.reduce boundaries, iteratee, L.latLngBounds([])
                bounds: bounds
            else
                return defaults

        postInitialize: ->
            @_addMouseoverListeners @allMarkers
            @popups = L.layerGroup()
            @popups.addTo @map
            @setInitialView()
            @drawInitialState()

        fitBbox: (bbox) =>
            sw = L.latLng(bbox.slice(0,2))
            ne = L.latLng(bbox.slice(2,4))
            bounds = L.latLngBounds(sw, ne)
            @map.fitBounds bounds

        getMaxAutoZoom: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                7
            else if layer == 'ortographic'
                9
            else
                12


        setInitialView: ->
            if @mapOpts?.bbox?
                @fitBbox @mapOpts.bbox
            else if @mapOpts?.fitAllUnits == true and not @units.isEmpty()
                latlngs = @units.map (u) -> u.getLatLng()
                bounds = L.latLngBounds latlngs
                @map.fitBounds bounds
            else
                opts = @calculateInitialOptions()
                if opts.bounds?
                    @map.fitBounds opts.bounds
                else
                    @map.setView opts.center, opts.zoom

        drawInitialState: =>
            if @selectedPosition.isSet()
                @handlePosition @selectedPosition.value(),
                    center: false,
                    skipRefit: true,
                    initial: true
            else if @selectedUnits.isSet()
                @drawUnits @units, noRefit: true
            else
                if @units.isSet()
                    @drawUnits @units
                if @divisions.isSet()
                    @divisionLayer.clearLayers()
                    @drawDivisions @divisions

        updateMarkers: (units) ->
            markers = units.map (unit) =>
                icon = @createIcon unit, @selectedServices
                id = unit.get 'id'
                @markers[id].setIcon(icon)
                unit.marker = @markers[id]
                return @markers[id]

        drawUnits: (units, options) ->
            cancelled = false
            options?.cancelToken?.addHandler -> cancelled = true
            @allMarkers.clearLayers()
            @allGeometries.clearLayers()
            if units.filters?.bbox?
                if @_skipBboxDrawing
                    return

            if cancelled then return
            unitsWithLocation = units.filter (unit) => unit.get('location')?

            if cancelled then return
            markers = unitsWithLocation.map (unit) => @createMarker(unit, options?.marker)

            if cancelled then return
            unitsWithGeometry = units.filter (unit) =>
              geometry = unit.attributes.geometry
              if geometry
                return geometry.type in ['LineString', 'MultiLineString', 'Polygon', 'MultiPolygon']
              else
                return false

            if cancelled then return
            geometries = unitsWithGeometry.map (unit) => @createGeometry(unit, unit.attributes.geometry)

            if units.length == 1
                @highlightSelectedUnit(units.models[0])
            else
                latLngs = _(markers).map (m) => m.getLatLng()
                unless options?.keepViewport
                    @preAdapt?()
                    @map.adaptToLatLngs latLngs

            if cancelled then return
            @allMarkers.addLayers markers

        highlightSelectedUnit: (unit) ->
            # Prominently highlight the marker whose details are being
            # examined by the user.
            unless unit?
                return
            marker = unit.marker
            popup = marker?.popup
            unless popup
                return
            popup.selected = true
            @_clearOtherPopups popup, clearSelected: true
            unless @popups.hasLayer popup
                popup.setLatLng marker.getLatLng()
                @popups.addLayer popup
            @listenToOnce unit, 'change:selected', (unit) =>
                unless unit.get 'selected'
                    $(marker?._icon).removeClass 'selected'
                    $(marker?.popup._wrapper).removeClass 'selected'
                    @popups.removeLayer marker?.popup

                    if unit.geometry?
                        @allGeometries.removeLayer(unit.geometry)
            $(marker?._icon).addClass 'selected'
            $(marker?.popup._wrapper).addClass 'selected'

            if unit.geometry?
                @allGeometries.addLayer(unit.geometry)


        _combineMultiPolygons: (multiPolygons) ->
            multiPolygons.map (mp) => mp.coordinates[0]

        drawDivisionGeometry: (geojson) ->
            mp = L.GeoJSON.geometryToLayer geojson,
                null, null,
                invert: true
                worldLatLngs: MapBaseView.WORLD_LAT_LNGS
                color: '#ff8400'
                weight: 3
                strokeOpacity: 1
                fillColor: '#000'
                fillOpacity: 0.2
            @map.adapt()
            mp.addTo @divisionLayer

        drawDivisionsAsGeoJSONWithDataAttached: (divisions, statistics, statisticsPath) ->
            type = dataviz.getStatisticsType(statisticsPath.split('.')[0])
            layer = dataviz.getStatisticsLayer(statisticsPath.split('.')[1])
            domainMax = Math.max(Object.keys(statistics.attributes).map( (id) ->
                comparisonKey = statistics.attributes[id]?[type]?[layer]?.comparison
                if isNaN(+statistics.attributes[id]?[type]?[layer]?[comparisonKey])
                then 0
                else +statistics.attributes[id][type][layer][comparisonKey]
            )...)
            app.vent.trigger 'statisticsDomainMax', domainMax
            geojson = divisions.map (division) =>
                geometry:
                    coordinates: division.get('boundary').coordinates
                    type: 'MultiPolygon'
                type: 'Feature'
                properties:
                    _.extend({}, statistics.attributes[division.get('origin_id')]?[type]?[layer], {name: division.get('name')})
            L.geoJson(geojson,
                weight: 1
                color: '#000'
                fillColor: '#000'
                style: (feature) ->
                    fillOpacity: +(feature.properties?.normalized? && feature.properties.normalized)
                onEachFeature: (feature, layer) ->
                    popupOpts =
                        className: 'position'
                        offset: L.point 0, -15
                    popup = L.popup(popupOpts)
                        .setContent jade.template('statistic-popup', feature.properties)
                    layer.bindPopup popup
            ).addTo(@map);

        drawDivisions: (divisions) ->
            geojson =
                coordinates: @_combineMultiPolygons divisions.pluck('boundary')
                type: 'MultiPolygon'
            @drawDivisionGeometry geojson

        drawDivision: (division) ->
            unless division?
                return
            @drawDivisionGeometry division.get('boundary')

        highlightUnselectedUnit: (unit) ->
            # Transiently highlight the unit which is being moused
            # over in search results or otherwise temporarily in focus.
            marker = unit.marker
            popup = marker?.popup
            if popup?.selected
                return
            @_clearOtherPopups popup, clearSelected: true
            if popup?
                $(marker.popup._wrapper).removeClass 'selected'
                popup.setLatLng marker?.getLatLng()
                @popups.addLayer popup

        clusterPopup: (event) ->
            cluster = event.layer
            # Maximum number of displayed names per cluster.
            COUNT_LIMIT = 3
            childCount = cluster.getChildCount()
            names = _.map cluster.getAllChildMarkers(), (marker) ->
                    p13n.getTranslatedAttr marker.unit.get('name')
                .sort()
            data = {}
            overflowCount = childCount - COUNT_LIMIT
            if overflowCount > 1
                names = names[0...COUNT_LIMIT]
                data.overflow_message = i18n.t 'general.more_units',
                    count: overflowCount
            data.names = names
            popuphtml = jade.getTemplate('popup_cluster') data
            popup = @createPopup()
            popup.setLatLng cluster.getBounds().getCenter()
            popup.setContent popuphtml
            cluster.popup = popup
            @map.on 'zoomstart', =>
                @popups.removeLayer popup
            popup

        _addMouseoverListeners: (markerClusterGroup)->
            @bindDelayedPopup markerClusterGroup, null,
                showEvent: 'clustermouseover'
                hideEvent: 'clustermouseout'
                popupCreateFunction: _.bind @clusterPopup, @
            markerClusterGroup.on 'spiderfied', (e) =>
                icon = $(e.target._spiderfied?._icon)
                icon?.fadeTo('fast', 0)

            @_lastOpenedClusterIcon = null
            markerClusterGroup.on 'spiderfied', (e) =>
                # Work around css hover forced opacity showing the
                # clicked cluster which should be hidden.
                if @_lastOpenedClusterIcon
                    L.DomUtil.removeClass @_lastOpenedClusterIcon, 'hidden'
                icon = e.target._spiderfied._icon
                L.DomUtil.addClass icon, 'hidden'
                @_lastOpenedClusterIcon = icon

        getZoomlevelToShowAllMarkers: ->
            layer = p13n.get('map_background_layer')
            if layer == 'guidemap'
                return 8
            else if layer == 'ortographic'
                return 8
            else
                return 14

        getServices: ->
            null

        createClusterIcon: (cluster) ->
            count = cluster.getChildCount()
            serviceIds = {}
            serviceId = null
            markers = cluster.getAllChildMarkers()
            services = @getServices()
            _.each markers, (marker) =>
                unless marker.unit?
                    return
                if marker.popup?
                    cluster.on 'remove', (event) =>
                        @popups.removeLayer marker.popup
                if not services or services.isEmpty()
                    root = marker.unit.get('root_ontologytreenodes')?[0] or 1400
                else
                    service = services.find (s) =>
                        s.get('root') in marker.unit.get('root_ontologytreenodes')
                    root = service?.get('root') or 1400
                serviceIds[root] = true
            cluster.on 'remove', (event) =>
                if cluster.popup?
                    @popups.removeLayer cluster.popup
            colors = _(serviceIds).map (val, id) =>
                app.colorMatcher.serviceRootIdColor id

            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasClusterIcon
            else
                ctor = widgets.CanvasClusterIcon
            iconOpts = {}
            if _(markers).find((m) => m?.unit?.collection?.hasReducedPriority())?
                iconOpts.reducedProminence = true
            new ctor count, @getIconSize(), colors, null,
                iconOpts

        getFeatureGroup: ->
            featureGroup = L.markerClusterGroup
                showCoverageOnHover: false
                maxClusterRadius: (zoom) =>
                    return if (zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()) then 4 else 30
                iconCreateFunction: (cluster) =>
                    @createClusterIcon cluster
                zoomToBoundsOnClick: true
            featureGroup._getExpandedVisibleBounds = ->
                bounds = featureGroup._map._originalGetBounds()
                sw = bounds._southWest
                ne = bounds._northEast
                latDiff = if L.Browser.mobile then 0 else Math.abs(sw.lat - ne.lat) / 4
                lngDiff = if L.Browser.mobile then 0 else Math.abs(sw.lng - ne.lng) / 4
                return new L.LatLngBounds(
                    new L.LatLng(sw.lat - latDiff, sw.lng - lngDiff, true),
                    new L.LatLng(ne.lat + latDiff, ne.lng + lngDiff, true))
            featureGroup

        createMarker: (unit, markerOptions) ->
            id = unit.get 'id'
            if id of @markers
                marker = @markers[id]
                marker.unit = unit
                unit.marker = marker
                return marker

            icon = @createIcon unit, @selectedServices
            marker = widgets.createMarker map.MapUtils.latLngFromGeojson(unit),
                reducedProminence: unit.collection?.hasReducedPriority()
                icon: icon
                zIndexOffset: 100
            marker.unit = unit
            unit.marker = marker
            if @selectMarker?
                marker.on 'click', @selectMarker

            marker.on 'remove', (event) =>
                marker = event.target
                if marker.popup?
                    @popups.removeLayer marker.popup

            popup = @createPopup unit
            popup.setLatLng marker.getLatLng()
            @bindDelayedPopup marker, popup

            @markers[id] = marker

        createGeometry: (unit, geometry, opts) ->
            id = unit.get 'id'
            if id of @geometries
                geometry = @geometries[id]
                unit.geometry = geometry
                return geometry

            geometry = L.geoJson geometry, style: (feature) =>
                weight: 8
                color: '#cc2121'
                opacity: 0.6

            unit.geometry = geometry

            @geometries[id] = geometry


        _clearOtherPopups: (popup, opts) ->
            @popups.eachLayer (layer) =>
                if layer == popup
                    return
                if opts?.clearSelected or not layer.selected
                    @popups.removeLayer layer

        bindDelayedPopup: (marker, popup, opts) ->
            showEvent = opts?.showEvent or 'mouseover'
            hideEvent = opts?.hideEvent or 'mouseout'
            delay = opts?.delay or 600
            if marker and popup
                marker.popup = popup
                popup.marker = marker

            prevent = false
            createdPopup = null

            popupOn = (event) =>
                unless prevent
                    if opts?.popupCreateFunction?
                        _popup = opts.popupCreateFunction(event)
                        createdPopup = _popup
                    else
                        _popup = popup
                    @_clearOtherPopups _popup, clearSelected: false
                    @popups.addLayer _popup
                prevent = false

            popupOff = (event) =>
                if opts?.popupCreateFunction
                    _popup = createdPopup
                else
                    _popup = popup
                if _popup?
                    if @selectedUnits? and _popup.marker?.unit == @selectedUnits.first()
                        prevent = true
                    else
                        @popups.removeLayer _popup
                _.delay (=> prevent = false), delay

            marker.on hideEvent, popupOff
            marker.on showEvent, _.debounce(popupOn, delay)

        createPopup: (unit, opts, offset) ->
            popup = @createPopupWidget opts, offset
            if unit?
                htmlContent = "<div class='unit-name'>#{unit.getText 'name'}</div>"
                popup.setContent htmlContent
            popup

        createPopupWidget: (opts, offset) ->
            defaults =
                closeButton: false
                autoPan: false
                zoomAnimation: false
                className: 'unit'
                maxWidth: 500
                minWidth: 150
            if opts?
                opts = _.defaults opts, defaults
            else
                opts = defaults
            if offset? then opts.offset = offset
            new widgets.LeftAlignedPopup opts

        transformProfileIds: (ids) ->
            newAttrs = {}
            for aid, value of ids
                switch
                    when aid.includes('A') then newAttrs[aid.charAt(0) + '1'] = value
                    when aid.includes('B') then newAttrs[aid.charAt(0) + '2'] = value
                    when aid.includes('C') then newAttrs[aid.charAt(0) + '3'] = value
            newAttrs

        getBorderColor: (unit) ->
            if _.isNull(unit.attributes.accessibility_viewpoints)
                color = null
            else
                viewpoints = unit.attributes.accessibility_viewpoints
                activeProfiles = p13n.getAccessibilityProfileIds()
                if _.isEmpty(activeProfiles)
                    color = null
                else
                    profiles = @transformProfileIds(activeProfiles)
                    for pid, value of profiles
                        if viewpoints[pid] == 'green'
                            color = '#00ff00'
                        else if viewpoints[pid] == 'red'
                            color = '#ff0000'
                            break
                        else
                            color = '#ccc'
            color

        createIcon: (unit, services) ->
            borderColor = @getBorderColor unit
            if borderColor
                fillColor = '#000'
            else
                fillColor = app.colorMatcher.unitColor(unit) or 'rgb(255, 255, 255)'
            if MARKER_POINT_VARIANT
                ctor = widgets.PointCanvasIcon
            else
                ctor = widgets.PlantCanvasIcon
            iconOptions = {}
            if unit.collection?.hasReducedPriority()
                iconOptions.reducedProminence = true
            icon = new ctor @getIconSize(), fillColor, unit.id, iconOptions, borderColor

    return MapBaseView
