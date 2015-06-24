define [
    'backbone',
    'leaflet'
], (
    Backbone,
    L
) ->
    # General functions taken from https://github.com/HSLdevcom/navigator-proto

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

    class Route extends Backbone.Model
        initialize: ->
            @set 'selected_itinerary', 0
            @set 'plan', null
            @listenTo @, 'change:selected_itinerary', =>
                @trigger 'change:plan', @

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
                url: appSettings.otp_backend
                data: data
                success: (data) =>
                    @xhr = null
                    if 'error' of data
                        @trigger 'error'
                        return

                    data = otpCleanup data
                    @set 'selected_itinerary', 0
                    @set 'plan', data.plan
                error: =>
                    @clear()
                    @trigger 'error'

            @xhr = $.ajax args

        getSelectedItinerary: ->
            @get('plan').itineraries[@get 'selected_itinerary']

        clear: ->
            @set 'plan', null

    exports =
        Route: Route
