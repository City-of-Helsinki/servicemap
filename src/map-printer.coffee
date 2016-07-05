define (require) ->
    i18n           = require 'i18next'
    leafletImage   = require 'leaflet-image'
    leafletImageIe = require 'leaflet-image-ie'
    jade           = require 'cs!app/jade'
    p13n           = require 'cs!app/p13n'
    sm             = require 'cs!app/base'
    draw           = require 'cs!app/draw'

    MAP_IMG_ELEMENT_ID = 'map-as-png'

    ieVersion = sm.getIeVersion()
    if ieVersion == 10
        leafletImage = leafletImageIe

    class SMPrinter
        constructor: (@mapView) ->
            # Webkit
            if window.matchMedia
                mediaQueryList = window.matchMedia 'print'
                mediaQueryList.addListener (mql) =>
                    if mql.matches
                        @printMap()
                    else
                        @afterPrint()

            # IE + FF
            window.onbeforeprint = => @printMap()
            window.onafterprint = => @afterPrint()

        printMap: (notOnBeforePrint) =>
            if !notOnBeforePrint and !document.getElementById 'map-as-png'
                alert i18n.t 'print.use_print_button'
                return
            if @makingPrint or @printed == false
                return

            @makingPrint = true
            @printed = false

            map = @mapView.map
            markers = @mapView.allMarkers._featureGroup._layers

            getClusteredUnits = (markerCluster) ->
                _.map markerCluster.getAllChildMarkers(), (mm) -> mm.unit

            mapBounds = map._originalGetBounds()

            vid = 0
            descriptions = []
            for own id, marker of markers
                unless mapBounds.contains marker.getLatLng() then return

                # Settings altered for printing. These will be reset after printing.
                printStore =
                    storeAttributes: ['iconSize', 'iconAnchor']
                for att in printStore.storeAttributes
                    if marker.options.icon.options[att]
                        printStore[att] = marker.options.icon.options[att]
                marker.options.icon.options.printStore = printStore

                # Icon size smaller than 70 causes clusters to misbehave when zooming in after printing
                iconSize = 70
                marker.options.icon.options.iconSize = new L.Point(iconSize, iconSize)
                # Adjust the icon anchor to correct place
                marker.options.icon.options.iconAnchor = new L.Point(3*iconSize/4, iconSize/4)

                marker.vid = ++vid
                # Don't throw the actual icon away
                marker._iconStore = marker._icon

                canvasIcon = document.createElement('canvas')
                canvasIcon.height = iconSize
                canvasIcon.width = iconSize
                ctx = canvasIcon.getContext('2d')
                drawer = new draw.NumberCircleMaker(iconSize/2);
                drawer.drawNumberedCircle(ctx, marker.vid)
                marker._icon = canvasIcon
                marker._icon.src = canvasIcon.toDataURL();

                description = {}
                description.number = marker.vid

                if marker instanceof L.MarkerCluster
                    # Adjust the icon anchor position for clusters with these magic numbers
                    marker.options.icon.options.iconAnchor = new L.Point(5*iconSize/6, iconSize / 6)
                    units = getClusteredUnits marker
                    description.units = _.map units, (u) -> u.toJSON()
                else
                    description.units = [marker.unit.toJSON()]

                descriptions.push description

            tableHtml = jade.template 'print-table', descriptions: descriptions
            printLogo = "<h1 id=\"print-logo\">#{document.location.hostname}</h1>"
            document.body.insertAdjacentHTML 'afterBegin', printLogo
            document.body.insertAdjacentHTML 'beforeEnd', tableHtml

            leafletImage map, (err, canvas) =>
                if err
                    throw err
                # add the image to DOM
                img = document.createElement 'img'
                img.src = canvas.toDataURL()
                img.id = MAP_IMG_ELEMENT_ID;
                document.getElementById('images').appendChild img
                @makingPrint = false
                if notOnBeforePrint
                    window.print()

        afterPrint: () =>
            if @makingPrint
                setTimeout afterPrint, 100
                return

            markers = window.mapView.allMarkers._featureGroup._layers;
            for own id, marker of markers
                # Remove the printed marker icon
                if marker._iconStore
                    $(marker._icon).remove()
                    delete marker._icon
                    marker._icon = marker._iconStore
                    delete marker._iconStore
                # Reset icon options
                if marker.options.icon.options.printStore
                    printStore = marker.options.icon.options.printStore
                    for att in printStore.storeAttributes
                        delete marker.options.icon.options[att]
                        if printStore[att]
                            marker.options.icon.options[att] = printStore[att]
                    delete marker.options.icon.options.printStore

            $('#map-as-png').remove()
            $('#list-of-units').remove()
            @printed = true
