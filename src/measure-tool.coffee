

class MeasureTool
  constructor: (@map) ->

  markers = []
  polyline = new L.polyline()
  points = []

  start: ->
    @map.on 'click', measure()
    
  stop: ->
    @map.off 'click', measure()
  
  measure: (ev) ->
    newMarker = new L.marker ev.latlng, {draggable: true, icon: new L.DivIcon()}
    newMarker.on 'drag', console.log("drag")
    newMarker.on 'dragend', console.log("dragend")
}

MeasureTool