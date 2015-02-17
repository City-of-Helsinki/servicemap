define ->

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

    class TransitMapMixin
        initializeTransitMap: (opts) ->
            @listenTo opts.route, 'change:plan', (route) =>
                if route.has 'plan'
                    @drawItinerary route
                else
                    @clearItinerary()
            if opts.selectedUnits?
                @listenTo opts.selectedUnits, 'reset', @clearItinerary
            if opts.selectedPosition?
                @listenTo opts.selectedPosition, 'change:value', @clearItinerary

        # Renders each leg of the route to the map
        createRouteLayerFromItinerary: (itinerary) ->
            routeLayer = L.featureGroup()
            alertLayer = L.featureGroup()
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
                    opacity: 0.8

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
                            alertpoly = new L.geoJson alert.geometry, style: style
                            if alert.alertDescriptionText
                                alertpoly.bindPopup alert.alertDescriptionText.someTranslation, closeButton: false
                            alertpoly.addTo alertLayer

                # Always show route and time information at the leg start position
                if false
                    stop = leg.from
                    lastStop = leg.to
                    point = y: stop.lat, x: stop.lon
                    icon = L.divIcon className: "navigator-div-icon"
                    label = "<span style='font-size: 24px;'><img src='static/images/#{google_icons[leg.routeType ? leg.mode]}' style='vertical-align: sub; height: 24px'/><span>#{leg.route}</span></span>"

                    marker = L.marker(new L.LatLng(point.y, point.x), {icon: icon}).addTo(routeLayer)
                        .bindPopup "<b>Time: #{moment(leg.startTime).format("HH:mm")}&mdash;#{moment(leg.endTime).format("HH:mm")}</b><br /><b>From:</b> #{stop.name or ""}<br /><b>To:</b> #{lastStop.name or ""}"

            route: routeLayer, alerts: alertLayer

        drawItinerary: (route) ->
            if @routeLayer?
                @clearItinerary()
            {route: @routeLayer, alerts: @alertLayer} =
                @createRouteLayerFromItinerary route.getSelectedItinerary()
            @map.refitAndAddLayer @routeLayer
            @map.addLayer @alertLayer
            #_.defer => window.mapView.fitItinerary(@routeLayer)

        clearItinerary: ->
            if @routeLayer
                @map.removeLayer @routeLayer
            if @alertLayer
                @map.removeLayer @alertLayer
            @routeLayer = null
            @alertLayer = null
