define (require) ->
    _                      = require 'underscore'

    widgets                = require 'cs!app/widgets'
    MeasureCloseButtonView = require 'cs!app/views/measure-close-button'

    class MeasureTool
        constructor: (@map) ->
            @isActive = null

        measureAddPoint: (ev) =>
            # Disable selecting/unselecting positions
            #@infoPopups.clearLayers()
            #@map.removeLayer @userPositionMarkers['clicked']
            #@hasClickedPosition = false

            newPoint = new L.marker(ev.latlng, {
                draggable:true,
                icon: new L.DivIcon({
                    iconSize: L.point([50,50]),
                    iconAnchor: L.point([25,56]),
                    popupAnchor: L.point([10,-50]),
                    className:"measure-tool-marker",
                    html: "<span class=icon-icon-address></span>"
                })
            })
            newPoint.on 'drag', () =>
                @updateLine()
                @updateDistance()
            newPoint.on 'dragend', @updateDistance
            newPoint.addTo @map
            @removeCursorTip()
            newPoint.bindPopup("<div class='measure-distance'></div>", {closeButton: false})
            newPoint.openPopup()
            @_markers.push newPoint
            @updateLine()
            @updateDistance()

        # Enables measuring distances by clicking the map
        activate: =>
            $("#map").addClass('measure-tool-active')
            @isActive = true
            @resetMeasureTool();
            # Marker points on measured route
            @_markers = []
            # Polyline for measured route
            @_polyline = new L.polyline([], {className: "measure-tool-polyline", weight: 4})
            @_polyline.addTo @map
            @map.on 'click', @measureAddPoint
            # Remove existing close button
            $('.measure-close-button').remove()
            # Add close button to control area
            @_closeButton = new widgets.ControlWrapper(new MeasureCloseButtonView(), position: 'bottomright')
            @_closeButton.addTo @map
            @createCursorTip()

        resetMeasureTool: () =>
            if @_polyline
                @map.removeLayer @_polyline
            if @_markers
                @_markers.map (m) =>
                    @map.removeLayer m
            @_markers = []
            @_points = []

        # Calculates the measured distance and shows the result in popup over the
        # final marker
        updateDistance: () =>
            dist = 0
            @_markers.map (m, index, arr) ->
                unless index == 0
                    dist += m._latlng.distanceTo(arr[index-1]._latlng)
            unless @_markers.length < 1
                @_markers[@_markers.length - 1].setPopupContent("<div class='unit-name'>#{dist.toFixed(0)}m</div>")
                @_markers[@_markers.length - 1].openPopup()

        # Adapts the polyline to marker positions
        updateLine: () =>
            points = [];
            @_markers.map (m) ->
                points.push m._latlng
            @_polyline = @_polyline.setLatLngs(points)

        # Deactivates measuring tool
        deactivate: =>
            $("#map").removeClass('measure-tool-active')
            @isActive = false
            @resetMeasureTool()
            @map.off 'click', @measureAddPoint
            @_closeButton.view.$el.remove();
            @removeCursorTip()

        followCursor: (ev) =>
            @$tip.css({
                left: ev.pageX - @$tip.width() / 2,
                top: ev.pageY - 30
            })

        createCursorTip: () =>
            @$tip = $("<div>", {id: 'measure-start', text: i18n.t('measuring_tool.start_tip')});
            $('body').append @$tip
            $(document).on 'mousemove', @followCursor

        removeCursorTip: () =>
            $(document).off 'mousemove', @followCursor
            @$tip.remove()

        getLastMarker: ->
            return @_markers[@_markers.length - 1]

