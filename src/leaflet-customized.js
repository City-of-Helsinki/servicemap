define(['leaflet'], function(L) {
    L.Map.prototype._originalGetBounds = L.Map.prototype.getBounds;
    return L;
});
