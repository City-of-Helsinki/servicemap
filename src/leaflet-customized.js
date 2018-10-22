define(['leaflet'], function(L) {
  L.Map.prototype._originalGetBounds = L.Map.prototype.getBounds

  L.Path.prototype.onRemove = function(map) {
    map
      .off('viewreset', this.projectLatlngs, this)
      .off('moveend', this._updatePath, this)

    if (this.options.clickable) {
      // This override removes the following line from original method:
      // this._map.off('click', this._onClick, this);
      this._map.off('mousemove', this._onMouseMove, this)
    }

    this._requestUpdate()

    this.fire('remove')
    this._map = null
  }

  return L
})
