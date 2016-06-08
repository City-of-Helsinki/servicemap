define ['leaflet'], (L) ->
    # Allow calling original getBounds when needed.
    # (leaflet.activearea overrides getBounds)
    L.Map.prototype._originalGetBounds = L.Map.prototype.getBounds
    return L
