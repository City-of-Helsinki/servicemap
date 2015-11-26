(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['leaflet', 'backbone', 'cs!app/map'], function(L, Backbone, _arg) {
    var MapStateModel, MapUtils, VIEWPOINTS, boundsFromRadius, _latitudeDeltaFromRadius, _longitudeDeltaFromRadius;
    MapUtils = _arg.MapUtils;
    VIEWPOINTS = {
      singleUnitImmediateVicinity: 200,
      singleObjectEmbedded: 400
    };
    _latitudeDeltaFromRadius = function(radiusMeters) {
      return (radiusMeters / 40075017) * 360;
    };
    _longitudeDeltaFromRadius = function(radiusMeters, latitude) {
      return _latitudeDeltaFromRadius(radiusMeters) / Math.cos(L.LatLng.DEG_TO_RAD * latitude);
    };
    boundsFromRadius = function(radiusMeters, latLng) {
      var delta, max, min;
      delta = L.latLng(_latitudeDeltaFromRadius(radiusMeters), _longitudeDeltaFromRadius(radiusMeters, latLng.lat));
      min = L.latLng(latLng.lat - delta.lat, latLng.lng - delta.lng);
      max = L.latLng(latLng.lat + delta.lat, latLng.lng + delta.lng);
      return L.latLngBounds([min, max]);
    };
    return MapStateModel = (function(_super) {
      __extends(MapStateModel, _super);

      function MapStateModel() {
        this.onSelectPosition = __bind(this.onSelectPosition, this);
        return MapStateModel.__super__.constructor.apply(this, arguments);
      }

      MapStateModel.prototype.initialize = function(opts, embedded) {
        this.opts = opts;
        this.embedded = embedded;
        this.userHasModifiedView = false;
        this.wasAutomatic = false;
        this.zoom = null;
        this.bounds = null;
        this.center = null;
        return this.listenTo(this.opts.selectedPosition, 'change:value', this.onSelectPosition);
      };

      MapStateModel.prototype.setMap = function(map) {
        this.map = map;
        this.map.mapState = this;
        return this.map.on('moveend', _.bind(this.onMoveEnd, this));
      };

      MapStateModel.prototype.onSelectPosition = function(position) {
        if (position.isSet()) {
          return this.setUserModified();
        }
      };

      MapStateModel.prototype.onMoveEnd = function() {
        if (!this.wasAutomatic) {
          this.setUserModified();
        }
        return this.wasAutomatic = false;
      };

      MapStateModel.prototype.setUserModified = function() {
        return this.userHasModifiedView = true;
      };

      MapStateModel.prototype.adaptToLayer = function(layer) {
        return this.adaptToBounds(layer.getBounds());
      };

      MapStateModel.prototype.adaptToBounds = function(bounds) {
        var EMBED_RADIUS, mapBounds, radiusFilter, unitsInsideMap, viewOptions, zoom, _ref;
        mapBounds = this.map.getBounds();
        if ((bounds != null) && (this.map.getZoom() === this.map.getBoundsZoom(bounds) && mapBounds.contains(bounds))) {
          return;
        }
        if ((_ref = this.opts.route) != null ? _ref.has('plan') : void 0) {
          if (bounds != null) {
            this.map.fitBounds(bounds, {
              paddingTopLeft: [20, 0],
              paddingBottomRight: [20, 20]
            });
          }
          return;
        }
        viewOptions = {
          center: null,
          zoom: null,
          bounds: null
        };
        zoom = Math.max(MapUtils.getZoomlevelToShowAllMarkers(), this.map.getZoom());
        EMBED_RADIUS = VIEWPOINTS['singleObjectEmbedded'];
        if (this.opts.selectedUnits.isSet()) {
          if (this.embedded === true) {
            viewOptions.zoom = null;
            viewOptions.bounds = boundsFromRadius(EMBED_RADIUS, MapUtils.latLngFromGeojson(this.opts.selectedUnits.first()));
          } else {
            viewOptions.center = MapUtils.latLngFromGeojson(this.opts.selectedUnits.first());
            viewOptions.zoom = zoom;
          }
        } else if (this.opts.selectedPosition.isSet()) {
          if (this.embedded === true) {
            viewOptions.zoom = null;
            viewOptions.bounds = boundsFromRadius(EMBED_RADIUS, MapUtils.latLngFromGeojson(this.opts.selectedPosition.value()));
          } else {
            viewOptions.center = MapUtils.latLngFromGeojson(this.opts.selectedPosition.value());
            radiusFilter = this.opts.selectedPosition.value().get('radiusFilter');
            if (radiusFilter != null) {
              viewOptions.zoom = null;
              viewOptions.bounds = bounds;
            } else {
              viewOptions.zoom = zoom;
            }
          }
        }
        if (this.opts.selectedDivision.isSet()) {
          viewOptions = this._widenToDivision(this.opts.selectedDivision.value(), viewOptions);
        }
        if (this.opts.services.size() || this.opts.searchResults.size() && this.opts.selectedUnits.isEmpty()) {
          if (bounds != null) {
            if (!(this.opts.selectedPosition.isEmpty() && mapBounds.contains(bounds))) {
              if (this.embedded === true) {
                this.map.fitBounds(bounds);
                return;
              } else {
                unitsInsideMap = this._objectsInsideBounds(mapBounds, this.opts.units);
                if (!(this.opts.selectedPosition.isEmpty() && unitsInsideMap)) {
                  viewOptions = this._widenViewMinimally(this.opts.units, viewOptions);
                }
              }
            }
          }
        }
        return this.setMapView(viewOptions);
      };

      MapStateModel.prototype.setMapView = function(viewOptions) {
        var bounds;
        if (viewOptions == null) {
          return;
        }
        bounds = viewOptions.bounds;
        if (bounds) {
          if (this.map.getZoom() === this.map.getBoundsZoom(bounds) && this.map.getBounds().contains(bounds)) {
            return;
          }
          return this.map.fitBounds(viewOptions.bounds, {
            paddingTopLeft: [20, 0],
            paddingBottomRight: [20, 20]
          });
        } else if (viewOptions.center && viewOptions.zoom) {
          return this.map.setView(viewOptions.center, viewOptions.zoom);
        }
      };

      MapStateModel.prototype.centerLatLng = function(latLng, opts) {
        var zoom;
        zoom = this.map.getZoom();
        if (this.opts.selectedPosition.isSet()) {
          zoom = MapUtils.getZoomlevelToShowAllMarkers();
        } else if (this.opts.selectedUnits.isSet()) {
          zoom = MapUtils.getZoomlevelToShowAllMarkers();
        }
        return this.map.setView(latLng, zoom);
      };

      MapStateModel.prototype.adaptToLatLngs = function(latLngs) {
        if (latLngs.length === 0) {
          return;
        }
        return this.adaptToBounds(L.latLngBounds(latLngs));
      };

      MapStateModel.prototype._objectsInsideBounds = function(bounds, objects) {
        return objects.find(function(object) {
          var latLng;
          latLng = MapUtils.latLngFromGeojson(object);
          if (latLng != null) {
            return bounds.contains(latLng);
          }
          return false;
        });
      };

      MapStateModel.prototype._widenToDivision = function(division, viewOptions) {
        var bounds, mapBounds;
        mapBounds = this.map.getBounds();
        viewOptions.center = null;
        viewOptions.zoom = null;
        bounds = L.latLngBounds(L.GeoJSON.geometryToLayer(division.get('boundary'), null, null, {}).getBounds());
        if (mapBounds.contains(bounds)) {
          viewOptions = null;
        } else {
          viewOptions.bounds = bounds;
        }
        return viewOptions;
      };

      MapStateModel.prototype._widenViewMinimally = function(units, viewOptions) {
        var UNIT_COUNT, center, countLeft, mapBounds, service, sortedUnits, topLatLngs, unit, unitsFound, _i, _len, _ref;
        UNIT_COUNT = 2;
        mapBounds = this.map.getBounds();
        center = viewOptions.center || this.map.getCenter();
        sortedUnits = units.chain().filter((function(_this) {
          return function(unit) {
            return unit.has('location');
          };
        })(this)).sortBy((function(_this) {
          return function(unit) {
            return center.distanceTo(MapUtils.latLngFromGeojson(unit));
          };
        })(this)).value();
        topLatLngs = [];
        unitsFound = {};
        if (this.opts.services.size()) {
          _.each(this.opts.services.pluck('id'), (function(_this) {
            return function(id) {
              return unitsFound[id] = UNIT_COUNT;
            };
          })(this));
          for (_i = 0, _len = sortedUnits.length; _i < _len; _i++) {
            unit = sortedUnits[_i];
            if (_.isEmpty(unitsFound)) {
              break;
            }
            service = (_ref = unit.collection.filters) != null ? _ref.service : void 0;
            if (service != null) {
              countLeft = unitsFound[service];
              if (countLeft != null) {
                unitsFound[service] -= 1;
                if (unitsFound[service] === 0) {
                  delete unitsFound[service];
                }
              }
              topLatLngs.push(MapUtils.latLngFromGeojson(unit));
            }
          }
        } else if (this.opts.searchResults.isSet()) {
          topLatLngs = _(sortedUnits).map((function(_this) {
            return function(unit) {
              return MapUtils.latLngFromGeojson(unit);
            };
          })(this));
        }
        if (sortedUnits != null ? sortedUnits.length : void 0) {
          viewOptions.bounds = L.latLngBounds(topLatLngs).extend(center);
          viewOptions.center = null;
          viewOptions.zoom = null;
        }
        return viewOptions;
      };

      MapStateModel.prototype.zoomIn = function() {
        this.wasAutomatic = true;
        return this.map.setZoom(this.map.getZoom() + 1);
      };

      return MapStateModel;

    })(Backbone.Model);
  });

}).call(this);

//# sourceMappingURL=map-state-model.js.map
