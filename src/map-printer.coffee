define [
    'cs!app/base',
    'i18next',
    'cs!app/p13n',
    'leaflet-image',
    'leaflet-image-ie',
    'cs!app/draw'
],(
    sm
    i18n,
    p13n,
    leafletImage,
    leafletImageIe,
    draw
) ->

    PRINT_LEGEND_ELEMENT_ID = 'list-of-units'
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
            if !notOnBeforePrint and !document.getElementById('map-as-png')
                alert i18n.t 'print.use_print_button'
                return
            if @makingPrint or @printed == false
                return
    
            @makingPrint = true
            @printed = false

            map = @mapView.map
            markers = @mapView.allMarkers._featureGroup._layers
            
            listOfUnits = document.createElement('div')
            listOfUnits.id = PRINT_LEGEND_ELEMENT_ID;
            document.body.appendChild(listOfUnits);
    
            # Counter for printed markers
            vid = (() ->
                num = 0
                inc = () -> ++num
                inc
            )()
            for own id, marker of markers
                # Settings altered for printing. These will be reset after printing.
                printStore = {storeAttributes: ['iconSize', 'iconAnchor'] }
                for att in printStore.storeAttributes
                    if marker.options.icon.options[att]
                        printStore[att] = marker.options.icon.options[att]
                marker.options.icon.options.printStore = printStore
    
                # Icon size smaller than 70 causes clusters to misbehave when zooming in after printing
                iconSize = 70
                marker.options.icon.options.iconSize = new L.Point(iconSize, iconSize)
                # Adjust the icon anchor to correct place
                marker.options.icon.options.iconAnchor = new L.Point(3*iconSize/4, iconSize/4)
    
                # map.getBounds and map._originalGetBounds both give the bounds
                # of the active area. -> Need to get whole #map bounds manually.
                bounds = map.getPixelBounds()
                sw = map.unproject(bounds.getBottomLeft())
                ne = map.unproject(bounds.getTopRight())
                if(new L.LatLngBounds(sw, ne).contains(marker.getLatLng()))
                    marker.vid = vid()
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
    
                    markerLegend = document.createElement 'div'
                    markerLegend.innerHTML = "<div>" + marker.vid + ": " + "</div>";
    
                    getClusteredUnits = (markerCluster) ->
                        unitNames = []
                        for own mid, mm of markerCluster._markers
                            unitNames.push mm.unit.attributes.name[p13n.getLanguage()]
                        for own mcid, mc of markerCluster._childClusters
                            unitNames = unitNames.concat getClusteredUnits(mc)
                        unitNames
    
                    if marker instanceof L.MarkerCluster
                        # Adjust the icon anchor position for clusters with these magic numbers
                        marker.options.icon.options.iconAnchor = new L.Point(5*iconSize/6, iconSize / 6)
                        unitNames = getClusteredUnits(marker)
                        for name in unitNames
                            div = document.createElement 'div'
                            div.className = 'printed-unit-name'
                            div.textContent = name
                            markerLegend.appendChild div
    
                    else
                        div = document.createElement 'div'
                        div.className = 'printed-unit-name'
                        div.textContent = marker.unit.attributes.name[p13n.getLanguage()]
                        markerLegend.appendChild div
                    listOfUnits.appendChild(markerLegend)
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