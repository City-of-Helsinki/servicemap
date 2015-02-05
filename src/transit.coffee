define [
    'backbone',
    'leaflet'
], (
    Backbone,
    L
) ->
    # General functions taken from https://github.com/HSLdevcom/navigator-proto

    # Original structure from:
    # https://github.com/reitti/reittiopas/blob/90a4d5f20bed3868b5fb608ee1a1c7ce77b70ed8/web/js/utils.coffee
    hslColors =
        #walk: '#9ab9c9' # walking; HSL official color is too light #bee4f8
        walk: '#7a7a7a' # changed from standard for legibility
        wait: '#999999' # waiting time at a stop
        1:    '#007ac9' # Helsinki internal bus lines
        2:    '#00985f' # Trams
        3:    '#007ac9' # Espoo internal bus lines
        4:    '#007ac9' # Vantaa internal bus lines
        5:    '#007ac9' # Regional bus lines
        6:    '#ff6319' # Metro
        7:    '#00b9e4' # Ferry
        8:    '#007ac9' # U-lines
        12:   '#64be14' # Commuter trains
        21:   '#007ac9' # Helsinki service lines
        22:   '#007ac9' # Helsinki night buses
        23:   '#007ac9' # Espoo service lines
        24:   '#007ac9' # Vantaa service lines
        25:   '#007ac9' # Region night buses
        36:   '#007ac9' # Kirkkonummi internal bus lines
        38:   '#007ac9' # Undocumented, assumed bus
        39:   '#007ac9' # Kerava internal bus lines
    googleColors =
        WALK: hslColors.walk
        CAR: hslColors.walk
        BICYCLE: hslColors.walk
        WAIT: hslColors.wait
        0: hslColors[2]
        1: hslColors[6]
        2: hslColors[12]
        3: hslColors[5]
        4: hslColors[7]
        109: hslColors[12]
    modeMap =
        tram: 'TRAM'
        bus: 'BUS'
        metro: 'SUBWAY'
        ferry: 'FERRY'
        train: 'RAIL'


    # Route received from OTP is encoded so it needs to be decoded.
    # translated from https://github.com/ahocevar/openlayers/blob/master/lib/OpenLayers/Format/EncodedPolyline.js
    decodePolyline = (encoded, dims) ->
        # Start from origo
        point = (0 for i in [0...dims])

        # Loop over the encoded input string
        i = 0
        points = while i < encoded.length
            for dim in [0...dims]
                result = 0
                shift = 0
                loop
                    b = encoded.charCodeAt(i++) - 63
                    result |= (b & 0x1f) << shift
                    shift += 5
                    break unless b >= 0x20

                point[dim] += if result & 1 then ~(result >> 1) else result >> 1

            # Keep a copy in the result list
            point.slice(0)

        return points

    # (taken from https://github.com/HSLdevcom/navigator-proto)
    # clean up oddities in routing result data from OTP
    otpCleanup = (data) ->
        for itinerary in data.plan?.itineraries or []
            legs = itinerary.legs
            length = legs.length
            last = length-1

            # if there's time past walking in either end, add that to walking
            # XXX what if it's not walking?
            if not legs[0].routeType and legs[0].startTime != itinerary.startTime
                legs[0].startTime = itinerary.startTime
                legs[0].duration = legs[0].endTime - legs[0].startTime
            if not legs[last].routeType and legs[last].endTime != itinerary.endTime
                legs[last].endTime = itinerary.endTime
                legs[last].duration = legs[last].endTime - legs[last].startTime

            newLegs = []
            time = itinerary.startTime # tracks when next leg should start
            for leg in itinerary.legs
                # Route received from OTP is encoded so it needs to be decoded.
                points = decodePolyline leg.legGeometry.points, 2
                points = ((x * 1e-5 for x in coords) for coords in points)
                leg.legGeometry.points = points

                # if there's unaccounted time before a walking leg
                if leg.startTime - time > 1000 and leg.routeType == null
                    # move non-transport legs to occur before wait time
                    waitTime = leg.startTime-time
                    time = leg.endTime
                    leg.startTime -= waitTime
                    leg.endTime -= waitTime
                    newLegs.push leg
                    # add the waiting time as a separate leg
                    newLegs.push createWaitLeg leg.endTime, waitTime,
                        _.last(leg.legGeometry.points), leg.to.name
                # else if there's unaccounted time before a leg
                else if leg.startTime - time > 1000
                    waitTime = leg.startTime-time
                    time = leg.endTime
                    # add the waiting time as a separate leg
                    newLegs.push createWaitLeg leg.startTime - waitTime,
                        waitTime, leg.legGeometry.points[0], leg.from.name
                    newLegs.push leg
                else
                    newLegs.push leg
                    time = leg.endTime # next leg should start when this ended
            itinerary.legs = newLegs
        return data

    createWaitLeg = (startTime, duration, point, placename) ->
        leg =
            mode: "WAIT"
            routeType: null # non-transport
            route: ""
            duration: duration
            startTime: startTime
            endTime: startTime + duration
            legGeometry: {points: [point]}
            from:
                lat: point[0]
                lon: point[1]
                name: placename
        leg.to = leg.from
        return leg

    # Renders each leg of the route to the map and also draws icons of real-time vehicle
    # locations to the map if available.
    renderRouteLayer = (itinerary, routeLayer) ->
        legs = itinerary.legs

        sum = (xs) -> _.reduce(xs, ((x, y) -> x+y), 0)
        totalWalkingDistance = sum(leg.distance for leg in legs when leg.distance and not leg.routeType?)
        totalWalkingDuration = sum(leg.duration for leg in legs when leg.distance and not leg.routeType?)

        routeIncludesTransit = _.any(leg.routeType? for leg in legs)

        mins = Math.ceil(itinerary.duration/1000/60)
        walkMins = Math.ceil(totalWalkingDuration/1000/60)
        walkKms = Math.ceil(totalWalkingDistance/100)/10

        for leg in legs
            points = (new L.LatLng(point[0], point[1]) for point in leg.legGeometry.points)
            color = googleColors[leg.routeType ? leg.mode]
            style =
                color: color
                stroke: true
                fill: false
                weight: 8
                opacity: 0 # Important: get rid of overly smoothed edges with opacity 0
                clickable: false

            polyline = new L.Polyline points, style
            polyline.addTo routeLayer # The route leg line is added to the routeLayer

            style.opacity = 0.8
            delete style.weight
            delete style.clickable

            polyline = new L.Polyline points, style
            # Make zooming to the leg via click possible.
            polyline.on 'click', (e) ->
                @._map.fitBounds(polyline.getBounds())
                if marker?
                    marker.openPopup()
            polyline.addTo routeLayer

            if leg.alerts
                style =
                    color: '#ff3333'
                    opacity: 0.2
                    fillOpacity: 0.4
                    weight: 5
                    clickable: true
                for alert in leg.alerts
                    if alert.geometry
                        alertpoly = new L.geoJson alert.geometry, {"style":style}
                        if alert.alertDescriptionText
                            alertpoly.bindPopup alert.alertDescriptionText.someTranslation, closeButton: false
                        alertpoly.addTo routeLayer

            # Always show route and time information at the leg start position
            if false
                stop = leg.from
                lastStop = leg.to
                point = {y: stop.lat, x: stop.lon}
                icon = L.divIcon({className: "navigator-div-icon"})
                label = "<span style='font-size: 24px;'><img src='static/images/#{google_icons[leg.routeType ? leg.mode]}' style='vertical-align: sub; height: 24px'/><span>#{leg.route}</span></span>"

                marker = L.marker(new L.LatLng(point.y, point.x), {icon: icon}).addTo(routeLayer)
                    .bindPopup("<b>Time: #{moment(leg.startTime).format("HH:mm")}&mdash;#{moment(leg.endTime).format("HH:mm")}</b><br /><b>From:</b> #{stop.name or ""}<br /><b>To:</b> #{lastStop.name or ""}")

            # The row causes all legs polylines to be returned as array from the renderRouteLayer function.
            # polyline is graphical representation of the leg.
            polyline

    OTP_URL = 'http://144.76.78.72/otp/routers/default/plan'
    class Route
        init: (@selectedUnits, @selectedPosition) ->
            _.extend @, Backbone.Events
            @selectedItinerary = 0
            if @selectedUnits?
                @listenTo @selectedUnits, 'reset', @clearItinerary
            if @selectedPosition?
                @listenTo @selectedPosition, 'change:value', @clearItinerary

        abort: ->
            if not @xhr
                return
            @xhr.abort()
            @xhr = null

        requestPlan: (from, to, opts) ->
            opts = opts or {}

            if @xhr
                @xhr.abort()
                @xhr = null

            modes = ['WALK']
            if opts.bicycle
                modes = ['BICYCLE']
            if opts.car
                if opts.transit
                    modes = ['CAR_PARK', 'WALK']
                else
                    modes = ['CAR']
            if opts.transit
                modes.push 'TRANSIT'
            else
                modes = _.union modes,
                    _(opts.modes).map (m) => modeMap[m]

            data =
                fromPlace: from
                toPlace: to
                mode: modes.join ','
                numItineraries: 3
                showIntermediateStops: 'true'
                locale: p13n.getLanguage()

            if opts.wheelchair
                data.wheelchair = true

            if opts.walkReluctance
                data.walkReluctance = opts.walkReluctance

            if opts.walkBoardCost
                data.walkBoardCost = opts.walkBoardCost

            if opts.walkSpeed
                data.walkSpeed = opts.walkSpeed

            if opts.minTransferTime
                data.minTransferTime = opts.minTransferTime

            if opts.date and opts.time
                data.date = opts.date
                data.time = opts.time

            if opts.arriveBy
                data.arriveBy = true

            args =
                dataType: 'json'
                url: OTP_URL
                data: data
                success: (data) =>
                    @xhr = null
                    if 'error' of data
                        @trigger 'error'
                        return

                    data = otpCleanup data
                    @plan = data.plan
                    @trigger 'plan', @plan
                error: =>
                    @trigger 'error'

            @xhr = $.ajax args

        getMap: ->
            window.mapView.map

        drawItinerary: (itineraryIndex) ->
            @selectedItinerary = if itineraryIndex? then itineraryIndex else 0
            it = @plan.itineraries[@selectedItinerary]
            if @routeLayer?
                @clearItinerary()
            @routeLayer = L.featureGroup()
            @routeLayer.addTo @getMap()
            renderRouteLayer it, @routeLayer
            window.mapView.recenter()
            _.defer => window.mapView.fitItinerary(@routeLayer)

        clearItinerary: ->
            if not @routeLayer?
                return
            @getMap().removeLayer @routeLayer
            @routeLayer = null

    exports =
        Route: Route
