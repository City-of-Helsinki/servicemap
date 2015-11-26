(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['leaflet', 'backbone', 'backbone.marionette', 'leaflet.markercluster', 'leaflet.activearea', 'i18next', 'cs!app/widgets', 'cs!app/models', 'cs!app/p13n', 'cs!app/jade', 'cs!app/map-base-view', 'cs!app/transit-map', 'cs!app/map', 'cs!app/base', 'cs!app/map-state-model', 'cs!app/views/exporting', 'cs!app/views/location-refresh-button'], function(leaflet, Backbone, Marionette, markercluster, leaflet_activearea, i18n, widgets, models, p13n, jade, MapBaseView, TransitMapMixin, map, _arg, MapStateModel, ExportingView, LocationRefreshButtonView) {
    var DEFAULT_CENTER, ICON_SIZE, MARKER_POINT_VARIANT, MapView, mixOf;
    mixOf = _arg.mixOf;
    ICON_SIZE = 40;
    if (getIeVersion() && getIeVersion() < 9) {
      ICON_SIZE *= .8;
    }
    MARKER_POINT_VARIANT = false;
    DEFAULT_CENTER = [60.171944, 24.941389];
    MapView = (function(_super) {
      __extends(MapView, _super);

      function MapView() {
        this.preAdapt = __bind(this.preAdapt, this);
        return MapView.__super__.constructor.apply(this, arguments);
      }

      MapView.prototype.tagName = 'div';

      MapView.prototype.initialize = function(opts, mapOpts) {
        this.opts = opts;
        this.mapOpts = mapOpts;
        MapView.__super__.initialize.call(this, this.opts, this.mapOpts);
        this.selectedServices = this.opts.services;
        this.searchResults = this.opts.searchResults;
        this.selectedDivision = this.opts.selectedDivision;
        this.userPositionMarkers = {
          accuracy: null,
          position: null,
          clicked: null
        };
        this.listenTo(this.selectedServices, 'add', (function(_this) {
          return function(service, collection) {
            if (collection.size() === 1) {
              return _this.markers = {};
            }
          };
        })(this));
        this.listenTo(this.selectedServices, 'remove', (function(_this) {
          return function(model, collection) {
            if (collection.size() === 0) {
              return _this.markers = {};
            }
          };
        })(this));
        this.listenTo(this.selectedDivision, 'change:value', (function(_this) {
          return function(model) {
            _this.divisionLayer.clearLayers();
            return _this.drawDivision(model.value());
          };
        })(this));
        this.listenTo(this.units, 'unit:highlight', this.highlightUnselectedUnit);
        this.listenTo(this.units, 'batch-remove', this.removeUnits);
        this.listenTo(this.units, 'remove', this.removeUnit);
        this.listenTo(this.selectedUnits, 'reset', this.handleSelectedUnit);
        this.listenTo(p13n, 'position', this.handlePosition);
        if (this.selectedPosition.isSet()) {
          this.listenTo(this.selectedPosition.value(), 'change:radiusFilter', this.radiusFilterChanged);
        }
        this.listenTo(this.selectedPosition, 'change:value', (function(_this) {
          return function(wrapper, value) {
            var previous;
            previous = wrapper.previous('value');
            if (previous != null) {
              _this.stopListening(previous);
            }
            if (value != null) {
              _this.listenTo(value, 'change:radiusFilter', _this.radiusFilterChanged);
            }
            return _this.handlePosition(value, {
              center: true
            });
          };
        })(this));
        MapView.setMapActiveAreaMaxHeight({
          maximize: this.selectedPosition.isEmpty() && this.selectedUnits.isEmpty()
        });
        return this.initializeTransitMap({
          route: this.opts.route,
          selectedUnits: this.selectedUnits,
          selectedPosition: this.selectedPosition
        });
      };

      MapView.prototype.onMapClicked = function(ev) {
        var position;
        if (this.hasClickedPosition == null) {
          this.hasClickedPosition = false;
        }
        if (this.hasClickedPosition) {
          this.infoPopups.clearLayers();
          this.map.removeLayer(this.userPositionMarkers['clicked']);
          return this.hasClickedPosition = false;
        } else {
          if (this.pendingPosition != null) {
            position = this.pendingPosition;
          } else {
            position = new models.CoordinatePosition({
              isDetected: false
            });
          }
          position.set('location', {
            coordinates: [ev.latlng.lng, ev.latlng.lat],
            accuracy: 0,
            type: 'Point'
          });
          if (this.pendingPosition != null) {
            this.pendingPosition = null;
            $('#map').css('cursor', 'auto');
          } else {
            position.set('name', null);
            this.hasClickedPosition = true;
          }
          return this.handlePosition(position, {
            initial: true
          });
        }
      };

      MapView.prototype.requestLocation = function(position) {
        $('#map').css('cursor', 'crosshair');
        return this.pendingPosition = position;
      };

      MapView.prototype.radiusFilterChanged = function(position, radius) {
        var latLng, poly;
        this.divisionLayer.clearLayers();
        if (radius == null) {
          return;
        }
        latLng = L.GeoJSON.geometryToLayer(position.get('location'));
        poly = new widgets.CirclePolygon(latLng.getLatLng(), radius, {
          invert: true,
          stroke: false
        });
        poly.circle.options.fill = false;
        poly.addTo(this.divisionLayer);
        return poly.circle.addTo(this.divisionLayer);
      };

      MapView.prototype.handleSelectedUnit = function(units, options) {
        var latLng, unit, _ref;
        if (units.isEmpty()) {
          this._removeBboxMarkers(this.map.getZoom(), map.MapUtils.getZoomlevelToShowAllMarkers());
          MapView.setMapActiveAreaMaxHeight({
            maximize: true
          });
          return;
        }
        unit = units.first();
        latLng = (_ref = unit.marker) != null ? _ref.getLatLng() : void 0;
        if (latLng != null) {
          this.map.adaptToLatLngs([latLng]);
        }
        if (!unit.hasBboxFilter()) {
          this._removeBboxMarkers();
          this._skipBboxDrawing = false;
        }
        return _.defer((function(_this) {
          return function() {
            return _this.highlightSelectedUnit(unit);
          };
        })(this));
      };

      MapView.prototype.handlePosition = function(positionObject, opts) {
        var accuracy, accuracyMarker, isSelected, key, latLng, layer, location, marker, pop, popup, prev, _i, _len, _ref;
        if (positionObject == null) {
          _ref = ['clicked', 'address'];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            key = _ref[_i];
            layer = this.userPositionMarkers[key];
            if (layer) {
              this.map.removeLayer(layer);
            }
          }
        }
        isSelected = positionObject === this.selectedPosition.value();
        key = positionObject != null ? positionObject.origin() : void 0;
        if (key !== 'detected') {
          this.infoPopups.clearLayers();
        }
        prev = this.userPositionMarkers[key];
        if (prev) {
          this.map.removeLayer(prev);
        }
        if ((key === 'address') && (this.userPositionMarkers.clicked != null)) {
          this.map.removeLayer(this.userPositionMarkers.clicked);
        }
        if ((key === 'clicked') && isSelected && (this.userPositionMarkers.address != null)) {
          this.map.removeLayer(this.userPositionMarkers.address);
        }
        location = positionObject != null ? positionObject.get('location') : void 0;
        if (!location) {
          return;
        }
        accuracy = location.accuracy;
        accuracyMarker = L.circle(latLng, accuracy, {
          weight: 0
        });
        latLng = map.MapUtils.latLngFromGeojson(positionObject);
        marker = map.MapUtils.createPositionMarker(latLng, accuracy, positionObject.origin());
        marker.position = positionObject;
        marker.on('click', (function(_this) {
          return function() {
            return app.commands.execute('selectPosition', positionObject);
          };
        })(this));
        if (isSelected || (opts != null ? opts.center : void 0)) {
          this.map.refitAndAddMarker(marker);
        } else {
          marker.addTo(this.map);
        }
        this.userPositionMarkers[key] = marker;
        if (isSelected) {
          this.infoPopups.clearLayers();
        }
        popup = this.createPositionPopup(positionObject, marker);
        if (!(positionObject != null ? positionObject.isDetectedLocation() : void 0) || this.selectedUnits.isEmpty() && (this.selectedPosition.isEmpty() || this.selectedPosition.value() === positionObject)) {
          pop = (function(_this) {
            return function() {
              return _this.infoPopups.addLayer(popup);
            };
          })(this);
          if (!positionObject.get('preventPopup')) {
            if (isSelected || ((opts != null ? opts.initial : void 0) && !positionObject.get('preventPopup'))) {
              pop();
              if (isSelected) {
                $(popup._wrapper).addClass('selected');
              }
            }
          }
        }
        return positionObject.popup = popup;
      };

      MapView.prototype.width = function() {
        return this.$el.width();
      };

      MapView.prototype.height = function() {
        return this.$el.height();
      };

      MapView.prototype.removeUnits = function(options) {
        this.allMarkers.clearLayers();
        this.drawUnits(this.units);
        if (!this.selectedUnits.isEmpty()) {
          this.highlightSelectedUnit(this.selectedUnits.first());
        }
        if (this.units.isEmpty()) {
          return this.showAllUnitsAtHighZoom();
        }
      };

      MapView.prototype.removeUnit = function(unit, units, options) {
        if (unit.marker != null) {
          this.allMarkers.removeLayer(unit.marker);
          return delete unit.marker;
        }
      };

      MapView.prototype.getServices = function() {
        return this.selectedServices;
      };

      MapView.prototype.createPositionPopup = function(positionObject, marker) {
        var address, latLng, offset, offsetY, popup, popupContents, popupOpts;
        latLng = map.MapUtils.latLngFromGeojson(positionObject);
        address = positionObject.humanAddress();
        if (!address) {
          address = i18n.t('map.retrieving_address');
        }
        if (positionObject === this.selectedPosition.value()) {
          popupContents = (function(_this) {
            return function(ctx) {
              return "<div class=\"unit-name\">" + ctx.name + "</div>";
            };
          })(this);
          offsetY = (function() {
            switch (positionObject.origin()) {
              case 'detected':
                return 10;
              case 'address':
                return 10;
              default:
                return 38;
            }
          })();
          popup = this.createPopup(null, null, L.point(0, offsetY)).setContent(popupContents({
            name: address
          })).setLatLng(latLng);
        } else {
          popupContents = (function(_this) {
            return function(ctx) {
              var $popupEl;
              ctx.detected = positionObject != null ? positionObject.isDetectedLocation() : void 0;
              $popupEl = $(jade.template('position-popup', ctx));
              $popupEl.on('click', function(e) {
                if (positionObject !== _this.selectedPosition.value()) {
                  e.stopPropagation();
                  _this.listenTo(positionObject, 'reverse-geocode', function() {
                    return app.commands.execute('selectPosition', positionObject);
                  });
                  marker.closePopup();
                  _this.infoPopups.clearLayers();
                  _this.map.removeLayer(positionObject.popup);
                  if (positionObject.isReverseGeocoded()) {
                    return positionObject.trigger('reverse-geocode');
                  }
                }
              });
              return $popupEl[0];
            };
          })(this);
          offsetY = (function() {
            switch (positionObject.origin()) {
              case 'detected':
                return -53;
              case 'clicked':
                return -15;
              case 'address':
                return -50;
            }
          })();
          offset = L.point(0, offsetY);
          popupOpts = {
            closeButton: false,
            className: 'position',
            autoPan: false,
            offset: offset,
            autoPanPaddingTopLeft: L.point(30, 80),
            autoPanPaddingBottomRight: L.point(30, 80)
          };
          popup = L.popup(popupOpts).setLatLng(latLng).setContent(popupContents({
            name: address
          }));
        }
        if (typeof positionObject.reverseGeocode === "function") {
          positionObject.reverseGeocode().done((function(_this) {
            return function() {
              return popup.setContent(popupContents({
                name: positionObject.humanAddress()
              }));
            };
          })(this));
        }
        return popup;
      };

      MapView.prototype.highlightSelectedUnit = function(unit) {
        var marker, popup;
        if (unit == null) {
          return;
        }
        marker = unit.marker;
        popup = marker != null ? marker.popup : void 0;
        if (!popup) {
          return;
        }
        popup.selected = true;
        this._clearOtherPopups(popup, {
          clearSelected: true
        });
        if (!this.popups.hasLayer(popup)) {
          popup.setLatLng(marker.getLatLng());
          this.popups.addLayer(popup);
        }
        this.listenToOnce(unit, 'change:selected', (function(_this) {
          return function(unit) {
            $(marker != null ? marker._icon : void 0).removeClass('selected');
            $(marker != null ? marker.popup._wrapper : void 0).removeClass('selected');
            return _this.popups.removeLayer(marker != null ? marker.popup : void 0);
          };
        })(this));
        $(marker != null ? marker._icon : void 0).addClass('selected');
        return $(marker != null ? marker.popup._wrapper : void 0).addClass('selected');
      };

      MapView.prototype.selectMarker = function(event) {
        var marker, unit;
        marker = event.target;
        unit = marker.unit;
        return app.commands.execute('selectUnit', unit);
      };

      MapView.prototype.drawUnit = function(unit, units, options) {
        var location, marker;
        location = unit.get('location');
        if (location != null) {
          marker = this.createMarker(unit);
          return this.allMarkers.addLayer(marker);
        }
      };

      MapView.prototype.getCenteredView = function() {
        if (this.selectedPosition.isSet()) {
          return {
            center: map.MapUtils.latLngFromGeojson(this.selectedPosition.value()),
            zoom: map.MapUtils.getZoomlevelToShowAllMarkers()
          };
        } else if (this.selectedUnits.isSet()) {
          return {
            center: map.MapUtils.latLngFromGeojson(this.selectedUnits.first()),
            zoom: Math.max(this.getMaxAutoZoom(), this.map.getZoom())
          };
        } else {
          return null;
        }
      };

      MapView.prototype.resetMap = function() {
        return window.location.reload(true);
      };

      MapView.prototype.handleP13nChange = function(path, newVal) {
        var mapStyle, newCrs, newLayer, oldCrs, oldLayer, _ref;
        if (path[0] !== 'map_background_layer') {
          return;
        }
        oldLayer = this.map._baseLayer;
        oldCrs = this.map.crs;
        mapStyle = p13n.get('map_background_layer');
        _ref = map.MapMaker.makeBackgroundLayer({
          style: mapStyle
        }), newLayer = _ref.layer, newCrs = _ref.crs;
        if (newCrs.code !== oldCrs.code) {
          this.resetMap();
          return;
        }
        this.map.addLayer(newLayer);
        this.map.removeLayer(oldLayer);
        return this.map._baseLayer = newLayer;
      };

      MapView.prototype.addMapActiveArea = function() {
        this.map.setActiveArea('active-area');
        return MapView.setMapActiveAreaMaxHeight({
          maximize: this.selectedUnits.isEmpty() && this.selectedPosition.isEmpty()
        });
      };

      MapView.prototype.initializeMap = function() {
        this.setInitialView();
        window.debugMap = map;
        this.listenTo(p13n, 'change', this.handleP13nChange);
        this.popups = L.layerGroup();
        this.infoPopups = L.layerGroup();
        L.control.zoom({
          position: 'bottomright',
          zoomInText: "<span class=\"icon-icon-zoom-in\"></span><span class=\"sr-only\">" + (i18n.t('assistive.zoom_in')) + "</span>",
          zoomOutText: "<span class=\"icon-icon-zoom-out\"></span><span class=\"sr-only\">" + (i18n.t('assistive.zoom_out')) + "</span>"
        }).addTo(this.map);
        new widgets.ControlWrapper(new LocationRefreshButtonView(), {
          position: 'bottomright'
        }).addTo(this.map);
        new widgets.ControlWrapper(new ExportingView(), {
          position: 'bottomright'
        }).addTo(this.map);
        this.popups.addTo(this.map);
        this.infoPopups.addTo(this.map);
        this.debugGrid = L.layerGroup().addTo(this.map);
        this.debugCircles = {};
        this._addMapMoveListeners();
        if (p13n.getLocationRequested()) {
          p13n.requestLocation();
        }
        this.previousZoomlevel = this.map.getZoom();
        return this.drawInitialState();
      };

      MapView.prototype._removeBboxMarkers = function(zoom, zoomLimit) {
        var toRemove;
        if (this.markers == null) {
          return;
        }
        if (this.markers.length === 0) {
          return;
        }
        if ((zoom != null) && (zoomLimit != null)) {
          if (zoom >= zoomLimit) {
            return;
          }
        }
        this._skipBboxDrawing = true;
        if (this.selectedServices.isSet()) {
          return;
        }
        toRemove = _.filter(this.markers, (function(_this) {
          return function(m) {
            var ret, unit, _ref;
            unit = m != null ? m.unit : void 0;
            return ret = (unit != null ? (_ref = unit.collection) != null ? _ref.hasReducedPriority() : void 0 : void 0) && !(unit != null ? unit.get('selected') : void 0);
          };
        })(this));
        app.commands.execute('clearFilters');
        this.allMarkers.removeLayers(toRemove);
        return this._clearOtherPopups(null, null);
      };

      MapView.prototype._addMapMoveListeners = function() {
        var zoomLimit;
        zoomLimit = map.MapUtils.getZoomlevelToShowAllMarkers();
        this.map.on('zoomanim', (function(_this) {
          return function(data) {
            _this._skipBboxDrawing = false;
            return _this._removeBboxMarkers(data.zoom, zoomLimit);
          };
        })(this));
        this.map.on('zoomend', (function(_this) {
          return function() {
            return _this._removeBboxMarkers(_this.map.getZoom(), zoomLimit);
          };
        })(this));
        return this.map.on('moveend', (function(_this) {
          return function() {
            if (_this.skipMoveend) {
              _this.skipMoveend = false;
              return;
            }
            return _this.showAllUnitsAtHighZoom();
          };
        })(this));
      };

      MapView.prototype.postInitialize = function() {
        this.addMapActiveArea();
        this.initializeMap();
        return this._addMouseoverListeners(this.allMarkers);
      };

      MapView.mapActiveAreaMaxHeight = function() {
        var screenHeight, screenWidth;
        screenWidth = $(window).innerWidth();
        screenHeight = $(window).innerHeight();
        return Math.min(screenWidth * 0.4, screenHeight * 0.3);
      };

      MapView.prototype.preAdapt = function() {
        return MapView.setMapActiveAreaMaxHeight();
      };

      MapView.setMapActiveAreaMaxHeight = function(options) {
        var $activeArea, defaults, height;
        defaults = {
          maximize: false
        };
        options = options || {};
        _.extend(defaults, options);
        options = defaults;
        if ($(window).innerWidth() <= appSettings.mobile_ui_breakpoint) {
          height = MapView.mapActiveAreaMaxHeight();
          $activeArea = $('.active-area');
          if (options.maximize) {
            $activeArea.css('height', 'auto');
            return $activeArea.css('bottom', 0);
          } else {
            $activeArea.css('height', height);
            return $activeArea.css('bottom', 'auto');
          }
        } else {
          $('.active-area').css('height', 'auto');
          return $('.active-area').css('bottom', 0);
        }
      };

      MapView.prototype.recenter = function() {
        var view;
        view = this.getCenteredView();
        if (view == null) {
          return;
        }
        return this.map.setView(view.center, view.zoom, {
          pan: {
            duration: 0.5
          }
        });
      };

      MapView.prototype.refitBounds = function() {
        this.skipMoveend = true;
        return this.map.fitBounds(this.allMarkers.getBounds(), {
          maxZoom: this.getMaxAutoZoom(),
          animate: true
        });
      };

      MapView.prototype.fitItinerary = function(layer) {
        return this.map.fitBounds(layer.getBounds(), {
          paddingTopLeft: [20, 20],
          paddingBottomRight: [20, 20]
        });
      };

      MapView.prototype.showAllUnitsAtHighZoom = function() {
        var bbox, bboxes, level, transformedBounds, _i, _len, _ref, _ref1;
        if ($(window).innerWidth() <= appSettings.mobile_ui_breakpoint) {
          return;
        }
        if (this.map.getZoom() >= map.MapUtils.getZoomlevelToShowAllMarkers()) {
          if (this.selectedUnits.isSet() && (((_ref = this.selectedUnits.first().collection) != null ? (_ref1 = _ref.filters) != null ? _ref1.bbox : void 0 : void 0) == null)) {
            return;
          }
          if (this.selectedServices.isSet()) {
            return;
          }
          if (this.searchResults.isSet()) {
            return;
          }
          transformedBounds = map.MapUtils.overlappingBoundingBoxes(this.map);
          bboxes = [];
          for (_i = 0, _len = transformedBounds.length; _i < _len; _i++) {
            bbox = transformedBounds[_i];
            bboxes.push("" + bbox[0][0] + "," + bbox[0][1] + "," + bbox[1][0] + "," + bbox[1][1]);
          }
          if (this.mapOpts.level != null) {
            level = this.mapOpts.level;
            delete this.mapOpts.level;
          }
          return app.commands.execute('addUnitsWithinBoundingBoxes', bboxes, level);
        }
      };

      return MapView;

    })(mixOf(MapBaseView, TransitMapMixin));
    return MapView;
  });

}).call(this);

//# sourceMappingURL=map-view.js.map
