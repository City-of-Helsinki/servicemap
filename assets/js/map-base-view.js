(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['backbone', 'backbone.marionette', 'i18next', 'leaflet', 'leaflet.markercluster', 'leaflet.snogylop', 'cs!app/map', 'cs!app/widgets', 'cs!app/jade', 'cs!app/map-state-model'], function(Backbone, Marionette, i18n, leaflet, markercluster, leaflet_snogylop, map, widgets, jade, MapStateModel) {
    var DEFAULT_CENTER, ICON_SIZE, MARKER_POINT_VARIANT, MapBaseView;
    MARKER_POINT_VARIANT = false;
    DEFAULT_CENTER = {
      helsinki: [60.171944, 24.941389],
      espoo: [60.19792, 24.708885],
      vantaa: [60.309045, 25.004675],
      kauniainen: [60.21174, 24.729595]
    };
    ICON_SIZE = 40;
    if (getIeVersion() && getIeVersion() < 9) {
      ICON_SIZE *= .8;
    }
    MapBaseView = (function(_super) {
      __extends(MapBaseView, _super);

      function MapBaseView() {
        this.drawInitialState = __bind(this.drawInitialState, this);
        this.fitBbox = __bind(this.fitBbox, this);
        return MapBaseView.__super__.constructor.apply(this, arguments);
      }

      MapBaseView.prototype.initialize = function(opts, mapOpts, embedded) {
        this.opts = opts;
        this.mapOpts = mapOpts;
        this.embedded = embedded;
        this.markers = {};
        this.units = this.opts.units;
        this.selectedUnits = this.opts.selectedUnits;
        this.selectedPosition = this.opts.selectedPosition;
        this.divisions = this.opts.divisions;
        this.listenTo(this.units, 'reset', this.drawUnits);
        return this.listenTo(this.units, 'finished', (function(_this) {
          return function(options) {
            _this.drawUnits(_this.units, options);
            if (_this.selectedUnits.isSet()) {
              return _this.highlightSelectedUnit(_this.selectedUnits.first());
            }
          };
        })(this));
      };

      MapBaseView.prototype.getProxy = function() {
        var fn;
        fn = (function(_this) {
          return function() {
            return map.MapUtils.overlappingBoundingBoxes(_this.map);
          };
        })(this);
        return {
          getTransformedBounds: fn
        };
      };

      MapBaseView.prototype.mapOptions = {};

      MapBaseView.prototype.render = function() {
        return this.$el.attr('id', 'map');
      };

      MapBaseView.prototype.getMapStateModel = function() {
        return new MapStateModel(this.opts, this.embedded);
      };

      MapBaseView.prototype.onShow = function() {
        var mapStyle, options;
        mapStyle = p13n.get('map_background_layer');
        options = {
          style: mapStyle,
          language: p13n.getLanguage()
        };
        this.map = map.MapMaker.createMap(this.$el.get(0), options, this.mapOptions, this.getMapStateModel());
        this.map.on('click', _.bind(this.onMapClicked, this));
        this.allMarkers = this.getFeatureGroup();
        this.allMarkers.addTo(this.map);
        this.divisionLayer = L.featureGroup();
        this.divisionLayer.addTo(this.map);
        return this.postInitialize();
      };

      MapBaseView.prototype.onMapClicked = function(ev) {};

      MapBaseView.prototype.calculateInitialOptions = function() {
        var boundaries, bounds, center, city, iteratee;
        if (this.selectedPosition.isSet()) {
          return {
            zoom: map.MapUtils.getZoomlevelToShowAllMarkers(),
            center: map.MapUtils.latLngFromGeojson(this.selectedPosition.value())
          };
        } else if (this.selectedUnits.isSet()) {
          return {
            zoom: this.getMaxAutoZoom(),
            center: map.MapUtils.latLngFromGeojson(this.selectedUnits.first())
          };
        } else if (this.divisions.isSet()) {
          boundaries = this.divisions.map((function(_this) {
            return function(d) {
              return new L.GeoJSON(d.get('boundary'));
            };
          })(this));
          iteratee = (function(_this) {
            return function(memo, value) {
              return memo.extend(value.getBounds());
            };
          })(this);
          bounds = _.reduce(boundaries, iteratee, L.latLngBounds([]));
          return {
            bounds: bounds
          };
        } else {
          city = p13n.get('city');
          if (city == null) {
            city = 'helsinki';
          }
          center = DEFAULT_CENTER[city];
          return {
            zoom: p13n.get('map_background_layer') === 'servicemap' ? 10 : 5,
            center: center
          };
        }
      };

      MapBaseView.prototype.postInitialize = function() {
        this._addMouseoverListeners(this.allMarkers);
        this.popups = L.layerGroup();
        this.popups.addTo(this.map);
        this.setInitialView();
        return this.drawInitialState();
      };

      MapBaseView.prototype.fitBbox = function(bbox) {
        var bounds, ne, sw;
        sw = L.latLng(bbox.slice(0, 2));
        ne = L.latLng(bbox.slice(2, 4));
        bounds = L.latLngBounds(sw, ne);
        return this.map.fitBounds(bounds);
      };

      MapBaseView.prototype.getMaxAutoZoom = function() {
        var layer;
        layer = p13n.get('map_background_layer');
        if (layer === 'guidemap') {
          return 7;
        } else if (layer === 'ortographic') {
          return 9;
        } else {
          return 12;
        }
      };

      MapBaseView.prototype.setInitialView = function() {
        var opts, _ref;
        if (((_ref = this.mapOpts) != null ? _ref.bbox : void 0) != null) {
          return this.fitBbox(this.mapOpts.bbox);
        } else {
          opts = this.calculateInitialOptions();
          if (opts.bounds != null) {
            return this.map.fitBounds(opts.bounds);
          } else {
            return this.map.setView(opts.center, opts.zoom);
          }
        }
      };

      MapBaseView.prototype.drawInitialState = function() {
        if (this.selectedPosition.isSet()) {
          return this.handlePosition(this.selectedPosition.value(), {
            center: false,
            skipRefit: true,
            initial: true
          });
        } else if (this.selectedUnits.isSet()) {
          return this.drawUnits(this.units, {
            noRefit: true
          });
        } else {
          if (this.units.isSet()) {
            this.drawUnits(this.units);
          }
          if (this.divisions.isSet()) {
            this.divisionLayer.clearLayers();
            return this.drawDivisions(this.divisions);
          }
        }
      };

      MapBaseView.prototype.drawUnits = function(units, options) {
        var latLngs, markers, unitsWithLocation, _ref;
        this.allMarkers.clearLayers();
        if (((_ref = units.filters) != null ? _ref.bbox : void 0) != null) {
          if (this._skipBboxDrawing) {
            return;
          }
        }
        unitsWithLocation = units.filter((function(_this) {
          return function(unit) {
            return unit.get('location') != null;
          };
        })(this));
        markers = unitsWithLocation.map((function(_this) {
          return function(unit) {
            return _this.createMarker(unit, options != null ? options.marker : void 0);
          };
        })(this));
        latLngs = _(markers).map((function(_this) {
          return function(m) {
            return m.getLatLng();
          };
        })(this));
        if (!(options != null ? options.keepViewport : void 0)) {
          if (typeof this.preAdapt === "function") {
            this.preAdapt();
          }
          this.map.adaptToLatLngs(latLngs);
        }
        return this.allMarkers.addLayers(markers);
      };

      MapBaseView.prototype._combineMultiPolygons = function(multiPolygons) {
        return multiPolygons.map((function(_this) {
          return function(mp) {
            return mp.coordinates[0];
          };
        })(this));
      };

      MapBaseView.prototype.drawDivisionGeometry = function(geojson) {
        var mp;
        mp = L.GeoJSON.geometryToLayer(geojson, null, null, {
          invert: true,
          color: '#ff8400',
          weight: 3,
          strokeOpacity: 1,
          fillColor: '#000',
          fillOpacity: 0.2
        });
        this.map.adapt();
        return mp.addTo(this.divisionLayer);
      };

      MapBaseView.prototype.drawDivisions = function(divisions) {
        var geojson;
        geojson = {
          coordinates: this._combineMultiPolygons(divisions.pluck('boundary')),
          type: 'MultiPolygon'
        };
        return this.drawDivisionGeometry(geojson);
      };

      MapBaseView.prototype.drawDivision = function(division) {
        if (division == null) {
          return;
        }
        return this.drawDivisionGeometry(division.get('boundary'));
      };

      MapBaseView.prototype.highlightUnselectedUnit = function(unit) {
        var marker, popup;
        marker = unit.marker;
        popup = marker != null ? marker.popup : void 0;
        if (popup != null ? popup.selected : void 0) {
          return;
        }
        this._clearOtherPopups(popup, {
          clearSelected: true
        });
        if (popup != null) {
          $(marker.popup._wrapper).removeClass('selected');
          popup.setLatLng(marker != null ? marker.getLatLng() : void 0);
          return this.popups.addLayer(popup);
        }
      };

      MapBaseView.prototype.clusterPopup = function(event) {
        var COUNT_LIMIT, childCount, cluster, data, names, overflowCount, popup, popuphtml;
        cluster = event.layer;
        COUNT_LIMIT = 3;
        childCount = cluster.getChildCount();
        names = _.map(cluster.getAllChildMarkers(), function(marker) {
          return p13n.getTranslatedAttr(marker.unit.get('name'));
        }).sort();
        data = {};
        overflowCount = childCount - COUNT_LIMIT;
        if (overflowCount > 1) {
          names = names.slice(0, COUNT_LIMIT);
          data.overflow_message = i18n.t('general.more_units', {
            count: overflowCount
          });
        }
        data.names = names;
        popuphtml = jade.getTemplate('popup_cluster')(data);
        popup = this.createPopup();
        popup.setLatLng(cluster.getBounds().getCenter());
        popup.setContent(popuphtml);
        cluster.popup = popup;
        this.map.on('zoomstart', (function(_this) {
          return function() {
            return _this.popups.removeLayer(popup);
          };
        })(this));
        return popup;
      };

      MapBaseView.prototype._addMouseoverListeners = function(markerClusterGroup) {
        this.bindDelayedPopup(markerClusterGroup, null, {
          showEvent: 'clustermouseover',
          hideEvent: 'clustermouseout',
          popupCreateFunction: _.bind(this.clusterPopup, this)
        });
        markerClusterGroup.on('spiderfied', (function(_this) {
          return function(e) {
            var icon, _ref;
            icon = $((_ref = e.target._spiderfied) != null ? _ref._icon : void 0);
            return icon != null ? icon.fadeTo('fast', 0) : void 0;
          };
        })(this));
        this._lastOpenedClusterIcon = null;
        return markerClusterGroup.on('spiderfied', (function(_this) {
          return function(e) {
            var icon;
            if (_this._lastOpenedClusterIcon) {
              L.DomUtil.removeClass(_this._lastOpenedClusterIcon, 'hidden');
            }
            icon = e.target._spiderfied._icon;
            L.DomUtil.addClass(icon, 'hidden');
            return _this._lastOpenedClusterIcon = icon;
          };
        })(this));
      };

      MapBaseView.prototype.getZoomlevelToShowAllMarkers = function() {
        var layer;
        layer = p13n.get('map_background_layer');
        if (layer === 'guidemap') {
          return 8;
        } else if (layer === 'ortographic') {
          return 8;
        } else {
          return 14;
        }
      };

      MapBaseView.prototype.getServices = function() {
        return null;
      };

      MapBaseView.prototype.createClusterIcon = function(cluster) {
        var colors, count, ctor, iconOpts, markers, serviceId, serviceIds, services;
        count = cluster.getChildCount();
        serviceIds = {};
        serviceId = null;
        markers = cluster.getAllChildMarkers();
        services = this.getServices();
        _.each(markers, (function(_this) {
          return function(marker) {
            var root, service;
            if (marker.unit == null) {
              return;
            }
            if (marker.popup != null) {
              cluster.on('remove', function(event) {
                return _this.popups.removeLayer(marker.popup);
              });
            }
            if (!services || services.isEmpty()) {
              root = marker.unit.get('root_services')[0];
            } else {
              service = services.find(function(s) {
                var _ref;
                return _ref = s.get('root'), __indexOf.call(marker.unit.get('root_services'), _ref) >= 0;
              });
              root = (service != null ? service.get('root') : void 0) || 50000;
            }
            return serviceIds[root] = true;
          };
        })(this));
        cluster.on('remove', (function(_this) {
          return function(event) {
            if (cluster.popup != null) {
              return _this.popups.removeLayer(cluster.popup);
            }
          };
        })(this));
        colors = _(serviceIds).map((function(_this) {
          return function(val, id) {
            return app.colorMatcher.serviceRootIdColor(id);
          };
        })(this));
        if (MARKER_POINT_VARIANT) {
          ctor = widgets.PointCanvasClusterIcon;
        } else {
          ctor = widgets.CanvasClusterIcon;
        }
        iconOpts = {};
        if (_(markers).find((function(_this) {
          return function(m) {
            var _ref, _ref1;
            return m != null ? (_ref = m.unit) != null ? (_ref1 = _ref.collection) != null ? _ref1.hasReducedPriority() : void 0 : void 0 : void 0;
          };
        })(this)) != null) {
          iconOpts.reducedProminence = true;
        }
        return new ctor(count, ICON_SIZE, colors, null, iconOpts);
      };

      MapBaseView.prototype.getFeatureGroup = function() {
        return L.markerClusterGroup({
          showCoverageOnHover: false,
          maxClusterRadius: (function(_this) {
            return function(zoom) {
              if (zoom >= map.MapUtils.getZoomlevelToShowAllMarkers()) {
                return 4;
              } else {
                return 30;
              }
            };
          })(this),
          iconCreateFunction: (function(_this) {
            return function(cluster) {
              return _this.createClusterIcon(cluster);
            };
          })(this),
          zoomToBoundsOnClick: true
        });
      };

      MapBaseView.prototype.createMarker = function(unit, markerOptions) {
        var icon, id, marker, popup, _ref;
        id = unit.get('id');
        if (id in this.markers) {
          marker = this.markers[id];
          marker.unit = unit;
          unit.marker = marker;
          return marker;
        }
        icon = this.createIcon(unit, this.selectedServices);
        marker = widgets.createMarker(map.MapUtils.latLngFromGeojson(unit), {
          reducedProminence: (_ref = unit.collection) != null ? _ref.hasReducedPriority() : void 0,
          icon: icon,
          zIndexOffset: 100
        });
        marker.unit = unit;
        unit.marker = marker;
        if (this.selectMarker != null) {
          this.listenTo(marker, 'click', this.selectMarker);
        }
        marker.on('remove', (function(_this) {
          return function(event) {
            marker = event.target;
            if (marker.popup != null) {
              return _this.popups.removeLayer(marker.popup);
            }
          };
        })(this));
        popup = this.createPopup(unit);
        popup.setLatLng(marker.getLatLng());
        this.bindDelayedPopup(marker, popup);
        return this.markers[id] = marker;
      };

      MapBaseView.prototype._clearOtherPopups = function(popup, opts) {
        return this.popups.eachLayer((function(_this) {
          return function(layer) {
            if (layer === popup) {
              return;
            }
            if ((opts != null ? opts.clearSelected : void 0) || !layer.selected) {
              return _this.popups.removeLayer(layer);
            }
          };
        })(this));
      };

      MapBaseView.prototype.bindDelayedPopup = function(marker, popup, opts) {
        var createdPopup, delay, hideEvent, popupOff, popupOn, prevent, showEvent;
        showEvent = (opts != null ? opts.showEvent : void 0) || 'mouseover';
        hideEvent = (opts != null ? opts.hideEvent : void 0) || 'mouseout';
        delay = (opts != null ? opts.delay : void 0) || 600;
        if (marker && popup) {
          marker.popup = popup;
          popup.marker = marker;
        }
        prevent = false;
        createdPopup = null;
        popupOn = (function(_this) {
          return function(event) {
            var _popup;
            if (!prevent) {
              if ((opts != null ? opts.popupCreateFunction : void 0) != null) {
                _popup = opts.popupCreateFunction(event);
                createdPopup = _popup;
              } else {
                _popup = popup;
              }
              _this._clearOtherPopups(_popup, {
                clearSelected: false
              });
              _this.popups.addLayer(_popup);
            }
            return prevent = false;
          };
        })(this);
        popupOff = (function(_this) {
          return function(event) {
            var _popup, _ref;
            if (opts != null ? opts.popupCreateFunction : void 0) {
              _popup = createdPopup;
            } else {
              _popup = popup;
            }
            if (_popup != null) {
              if ((_this.selectedUnits != null) && ((_ref = _popup.marker) != null ? _ref.unit : void 0) === _this.selectedUnits.first()) {
                prevent = true;
              } else {
                _this.popups.removeLayer(_popup);
              }
            }
            return _.delay((function() {
              return prevent = false;
            }), delay);
          };
        })(this);
        marker.on(hideEvent, popupOff);
        return marker.on(showEvent, _.debounce(popupOn, delay));
      };

      MapBaseView.prototype.createPopup = function(unit, opts, offset) {
        var htmlContent, popup;
        popup = this.createPopupWidget(opts, offset);
        if (unit != null) {
          htmlContent = "<div class='unit-name'>" + (unit.getText('name')) + "</div>";
          popup.setContent(htmlContent);
        }
        return popup;
      };

      MapBaseView.prototype.createPopupWidget = function(opts, offset) {
        var defaults;
        defaults = {
          closeButton: false,
          autoPan: false,
          zoomAnimation: false,
          className: 'unit',
          maxWidth: 500,
          minWidth: 150
        };
        if (opts != null) {
          opts = _.defaults(opts, defaults);
        } else {
          opts = defaults;
        }
        if (offset != null) {
          opts.offset = offset;
        }
        return new widgets.LeftAlignedPopup(opts);
      };

      MapBaseView.prototype.createIcon = function(unit, services) {
        var color, ctor, icon, iconOptions, _ref;
        color = app.colorMatcher.unitColor(unit) || 'rgb(255, 255, 255)';
        if (MARKER_POINT_VARIANT) {
          ctor = widgets.PointCanvasIcon;
        } else {
          ctor = widgets.PlantCanvasIcon;
        }
        iconOptions = {};
        if ((_ref = unit.collection) != null ? _ref.hasReducedPriority() : void 0) {
          iconOptions.reducedProminence = true;
        }
        return icon = new ctor(ICON_SIZE, color, unit.id, iconOptions);
      };

      return MapBaseView;

    })(Backbone.Marionette.View);
    return MapBaseView;
  });

}).call(this);

//# sourceMappingURL=map-base-view.js.map
