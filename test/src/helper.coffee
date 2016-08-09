exports.resetSession = (browser) ->
    browser.quit()
    browser = browser.init
        browserName: browser.browserTitle
    
# Helper functions to get js string to be evaluated with
# asserters.jsCondition
exports.isNearMapCenter = (location, delta = 1e-4) ->
    MAP_CENTER = 'app.getRegion("map").currentView.map.getCenter()'
    initialCenter =
        lat: MAP_CENTER + '.lat'
        lng: MAP_CENTER + '.lng'
    isNear = (x) =>
        'Math.abs(' + x + ') < ' + delta
    subLat = initialCenter.lat + ' - ' + location.lat
    latIsNear = isNear subLat
    subLng = initialCenter.lng + ' - ' + location.lng
    lngIsNear = isNear subLng
    return "#{latIsNear} && #{lngIsNear}"
exports.containsBbox = (bbox) ->
    MAP_BOUNDS = 'app.getRegion("map").currentView.map.getBounds()'
    BBOX_BOUNDS = "new L.LatLngBounds( new L.LatLng(#{bbox.sw}), new L.LatLng(#{bbox.ne}))"
    return "#{MAP_BOUNDS}.contains(#{BBOX_BOUNDS})"
exports.containsPoint = (point) ->
    MAP_BOUNDS = 'app.getRegion("map").currentView.map.getBounds()'
    POINT = "new L.LatLng(#{point.lat}, #{point.lng})"
    return "#{MAP_BOUNDS}.contains(#{POINT})"
    
module.exports = exports
