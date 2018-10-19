define(['leaflet', 'leaflet.markercluster'], function(L) {
  var _originalAnimationUnspiderfy =
    L.MarkerCluster.prototype._animationUnspiderfy

  L.MarkerCluster.prototype._animationUnspiderfy = function() {
    _originalAnimationUnspiderfy.apply(this, arguments)

    var group = this._group
    var cluster = this

    setTimeout(function() {
      group.fire('unspiderfied', { cluster: cluster })
    }, 200)
  }

  var _originalNoanimationUnspiderfy =
    L.MarkerCluster.prototype._noanimationUnspiderfy

  L.MarkerCluster.prototype._noanimationUnspiderfy = function() {
    _originalNoanimationUnspiderfy.apply(this, arguments)

    var group = this._group
    var cluster = this

    setTimeout(function() {
      group.fire('unspiderfied', { cluster: cluster })
    }, 200)
  }
})
