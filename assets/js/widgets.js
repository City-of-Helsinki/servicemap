(function() {
  var __slice = [].slice;

  define(['cs!app/draw', 'leaflet', 'leaflet.markercluster', 'underscore', 'jquery', 'backbone', 'cs!app/jade'], function(draw, leaflet, markercluster, _, $, Backbone, jade) {
    var CanvasIcon, CirclePolygon, REDUCED_OPACITY, SMMarker, anchor, createMarker, initializer;
    anchor = function(size) {
      var x, y;
      x = size.x / 3 + 5;
      y = size.y / 2 + 16;
      return new L.Point(x, y);
    };
    SMMarker = L.Marker;
    REDUCED_OPACITY = 1;
    initializer = function() {
      var OriginalMarkerCluster, SMMarkerCluster;
      REDUCED_OPACITY = 0.5;
      OriginalMarkerCluster = L.MarkerCluster;
      SMMarkerCluster = L.MarkerCluster.extend({
        setOpacity: function(opacity) {
          var children, reducedProminence, _ref, _ref1;
          children = this.getAllChildMarkers();
          reducedProminence = false;
          if (children.length) {
            reducedProminence = (_ref = children[0].unit) != null ? (_ref1 = _ref.collection) != null ? _ref1.hasReducedPriority() : void 0 : void 0;
          }
          if (reducedProminence && opacity === 1) {
            opacity = REDUCED_OPACITY;
          }
          return OriginalMarkerCluster.prototype.setOpacity.call(this, opacity);
        }
      });
      L.MarkerCluster = SMMarkerCluster;
      return SMMarker = L.Marker.extend({
        setOpacity: function(opacity) {
          if (this.options.reducedProminence && opacity === 1) {
            opacity = REDUCED_OPACITY;
          }
          return L.Marker.prototype.setOpacity.call(this, opacity);
        }
      });
    };
    createMarker = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(SMMarker, args, function(){});
    };
    CanvasIcon = L.Icon.extend({
      initialize: function(dimension, options) {
        this.dimension = dimension;
        this.options.iconSize = new L.Point(this.dimension, this.dimension);
        this.options.iconAnchor = this.iconAnchor();
        this.options.reducedProminence = options.reducedProminence;
        return this.options.pixelRatio = function(el) {
          var backingStoreRatio, context, devicePixelRatio;
          context = el.getContext('2d');
          devicePixelRatio = window.devicePixelRatio || 1;
          backingStoreRatio = context.webkitBackingStorePixelRatio || context.mozBackingStorePixelRatio || context.msBackingStorePixelRatio || context.oBackingStorePixelRatio || context.backingStorePixelRatio || 1;
          return devicePixelRatio / backingStoreRatio;
        };
      },
      options: {
        className: 'leaflet-canvas-icon'
      },
      setupCanvas: function() {
        var context, el, ratio, s;
        el = document.createElement('canvas');
        context = el.getContext('2d');
        ratio = this.options.pixelRatio(el);
        if (typeof G_vmlCanvasManager !== "undefined" && G_vmlCanvasManager !== null) {
          G_vmlCanvasManager.initElement(el);
        }
        this._setIconStyles(el, 'icon');
        s = this.options.iconSize;
        el.width = s.x * ratio;
        el.height = s.y * ratio;
        el.style.width = s.x + 'px';
        el.style.height = s.y + 'px';
        context.scale(ratio, ratio);
        if (this.options.reducedProminence) {
          L.DomUtil.setOpacity(el, REDUCED_OPACITY);
        }
        return el;
      },
      createIcon: function() {
        var el;
        el = this.setupCanvas();
        this.draw(el.getContext('2d'));
        return el;
      },
      createShadow: function() {
        return null;
      },
      iconAnchor: function() {
        return anchor(this.options.iconSize);
      }
    });
    CirclePolygon = L.Polygon.extend({
      initialize: function(latLng, radius, options) {
        var latLngs;
        this.circle = L.circle(latLng, radius);
        latLngs = this._calculateLatLngs();
        return L.Polygon.prototype.initialize.call(this, [latLngs], options);
      },
      _calculateLatLngs: function() {
        var STEPS, bounds, center, east, i, latRadius, lngRadius, north, rad, _i, _results;
        bounds = this.circle.getBounds();
        north = bounds.getNorth();
        east = bounds.getEast();
        center = this.circle.getLatLng();
        lngRadius = east - center.lng;
        latRadius = north - center.lat;
        STEPS = 180;
        _results = [];
        for (i = _i = 0; 0 <= STEPS ? _i < STEPS : _i > STEPS; i = 0 <= STEPS ? ++_i : --_i) {
          rad = (2 * i * Math.PI) / STEPS;
          _results.push([center.lat + Math.sin(rad) * latRadius, center.lng + Math.cos(rad) * lngRadius]);
        }
        return _results;
      }
    });
    return {
      PlantCanvasIcon: CanvasIcon.extend({
        initialize: function(dimension, color, id, options) {
          this.dimension = dimension;
          this.color = color;
          CanvasIcon.prototype.initialize.call(this, this.dimension, options);
          return this.plant = new draw.Plant(this.dimension, this.color, id);
        },
        draw: function(ctx) {
          return this.plant.draw(ctx);
        }
      }),
      PointCanvasIcon: CanvasIcon.extend({
        initialize: function(dimension, color, id) {
          this.dimension = dimension;
          this.color = color;
          CanvasIcon.prototype.initialize.call(this, this.dimension);
          return this.drawer = new draw.PointPlant(this.dimension, this.color, 2);
        },
        draw: function(ctx) {
          return this.drawer.draw(ctx);
        }
      }),
      CanvasClusterIcon: CanvasIcon.extend({
        initialize: function(count, dimension, colors, id, options) {
          var rotations, translations, _i, _ref, _results;
          this.count = count;
          this.dimension = dimension;
          this.colors = colors;
          CanvasIcon.prototype.initialize.call(this, this.dimension, options);
          this.options.iconSize = new L.Point(this.dimension + 30, this.dimension + 30);
          if (this.count > 5) {
            this.count = 5;
          }
          rotations = [130, 110, 90, 70, 50];
          translations = [[0, 5], [10, 7], [12, 8], [15, 10], [5, 12]];
          return this.plants = _.map((function() {
            _results = [];
            for (var _i = 1, _ref = this.count; 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--){ _results.push(_i); }
            return _results;
          }).apply(this), (function(_this) {
            return function(i) {
              return new draw.Plant(_this.dimension, _this.colors[(i - 1) % _this.colors.length], id, rotations[i - 1], translations[i - 1]);
            };
          })(this));
        },
        draw: function(ctx) {
          var plant, _i, _len, _ref, _results;
          _ref = this.plants;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            plant = _ref[_i];
            _results.push(plant.draw(ctx));
          }
          return _results;
        }
      }),
      PointCanvasClusterIcon: CanvasIcon.extend({
        initialize: function(count, dimension, colors, id) {
          var range, _i, _ref, _results;
          this.dimension = dimension;
          this.colors = colors;
          CanvasIcon.prototype.initialize.call(this, this.dimension);
          this.count = (Math.min(20, count) / 5) * 5;
          this.radius = 2;
          range = (function(_this) {
            return function() {
              return _this.radius + Math.random() * (_this.dimension - 2 * _this.radius);
            };
          })(this);
          this.positions = _.map((function() {
            _results = [];
            for (var _i = 1, _ref = this.count; 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--){ _results.push(_i); }
            return _results;
          }).apply(this), (function(_this) {
            return function(i) {
              return [range(), range()];
            };
          })(this));
          return this.clusterDrawer = new draw.PointCluster(this.dimension, this.colors, this.positions, this.radius);
        },
        draw: function(ctx) {
          return this.clusterDrawer.draw(ctx);
        }
      }),
      LeftAlignedPopup: L.Popup.extend({
        _updatePosition: function() {
          var animated, offset, pos, properOffset;
          if (!this._map) {
            return;
          }
          pos = this._map.latLngToLayerPoint(this._latlng);
          animated = this._animated;
          offset = L.point(this.options.offset);
          properOffset = {
            x: 15,
            y: -27
          };
          if (animated) {
            pos.y = pos.y + properOffset.y;
            pos.x = pos.x + properOffset.x;
            L.DomUtil.setPosition(this._container, pos);
          }
          this._containerBottom = -offset.y - (animated ? 0 : pos.y + properOffset.y);
          this._containerLeft = offset.x + (animated ? 0 : pos.x + properOffset.x);
          this._container.style.bottom = this._containerBottom + 'px';
          return this._container.style.left = this._containerLeft + 'px';
        }
      }),
      ControlWrapper: L.Control.extend({
        initialize: function(view, options) {
          this.view = view;
          return L.Util.setOptions(this, options);
        },
        onAdd: function(map) {
          return this.view.render();
        }
      }),
      initializer: initializer,
      createMarker: createMarker,
      CirclePolygon: CirclePolygon
    };
  });

}).call(this);

//# sourceMappingURL=widgets.js.map
