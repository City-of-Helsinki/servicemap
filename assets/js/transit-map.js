(function() {
  define(function() {
    var TransitMapMixin, googleColors, hslColors;
    hslColors = {
      walk: '#7a7a7a',
      wait: '#999999',
      1: '#007ac9',
      2: '#00985f',
      3: '#007ac9',
      4: '#007ac9',
      5: '#007ac9',
      6: '#ff6319',
      7: '#00b9e4',
      8: '#007ac9',
      12: '#64be14',
      21: '#007ac9',
      22: '#007ac9',
      23: '#007ac9',
      24: '#007ac9',
      25: '#007ac9',
      36: '#007ac9',
      38: '#007ac9',
      39: '#007ac9'
    };
    googleColors = {
      WALK: hslColors.walk,
      CAR: hslColors.walk,
      BICYCLE: hslColors.walk,
      WAIT: hslColors.wait,
      0: hslColors[2],
      1: hslColors[6],
      2: hslColors[12],
      3: hslColors[5],
      4: hslColors[7],
      109: hslColors[12]
    };
    return TransitMapMixin = (function() {
      function TransitMapMixin() {}

      TransitMapMixin.prototype.initializeTransitMap = function(opts) {
        this.listenTo(opts.route, 'change:plan', (function(_this) {
          return function(route) {
            if (route.has('plan')) {
              return _this.drawItinerary(route);
            } else {
              return _this.clearItinerary();
            }
          };
        })(this));
        if (opts.selectedUnits != null) {
          this.listenTo(opts.selectedUnits, 'reset', this.clearItinerary);
        }
        if (opts.selectedPosition != null) {
          return this.listenTo(opts.selectedPosition, 'change:value', this.clearItinerary);
        }
      };

      TransitMapMixin.prototype.createRouteLayerFromItinerary = function(itinerary) {
        var alert, alertLayer, alertpoly, color, icon, label, lastStop, leg, legs, marker, mins, point, points, polyline, routeIncludesTransit, routeLayer, stop, style, sum, totalWalkingDistance, totalWalkingDuration, walkKms, walkMins, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        routeLayer = L.featureGroup();
        alertLayer = L.featureGroup();
        legs = itinerary.legs;
        sum = function(xs) {
          return _.reduce(xs, (function(x, y) {
            return x + y;
          }), 0);
        };
        totalWalkingDistance = sum((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = legs.length; _i < _len; _i++) {
            leg = legs[_i];
            if (leg.distance && (leg.routeType == null)) {
              _results.push(leg.distance);
            }
          }
          return _results;
        })());
        totalWalkingDuration = sum((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = legs.length; _i < _len; _i++) {
            leg = legs[_i];
            if (leg.distance && (leg.routeType == null)) {
              _results.push(leg.duration);
            }
          }
          return _results;
        })());
        routeIncludesTransit = _.any((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = legs.length; _i < _len; _i++) {
            leg = legs[_i];
            _results.push(leg.routeType != null);
          }
          return _results;
        })());
        mins = Math.ceil(itinerary.duration / 1000 / 60);
        walkMins = Math.ceil(totalWalkingDuration / 1000 / 60);
        walkKms = Math.ceil(totalWalkingDistance / 100) / 10;
        for (_i = 0, _len = legs.length; _i < _len; _i++) {
          leg = legs[_i];
          points = (function() {
            var _j, _len1, _ref, _results;
            _ref = leg.legGeometry.points;
            _results = [];
            for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
              point = _ref[_j];
              _results.push(new L.LatLng(point[0], point[1]));
            }
            return _results;
          })();
          color = googleColors[(_ref = leg.routeType) != null ? _ref : leg.mode];
          style = {
            color: color,
            stroke: true,
            fill: false,
            opacity: 0.8
          };
          polyline = new L.Polyline(points, style);
          polyline.on('click', function(e) {
            this._map.fitBounds(polyline.getBounds());
            if (typeof marker !== "undefined" && marker !== null) {
              return marker.openPopup();
            }
          });
          polyline.addTo(routeLayer);
          if (leg.alerts) {
            style = {
              color: '#ff3333',
              opacity: 0.2,
              fillOpacity: 0.4,
              weight: 5,
              clickable: true
            };
            _ref1 = leg.alerts;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              alert = _ref1[_j];
              if (alert.geometry) {
                alertpoly = new L.geoJson(alert.geometry, {
                  style: style
                });
                if (alert.alertDescriptionText) {
                  alertpoly.bindPopup(alert.alertDescriptionText.someTranslation, {
                    closeButton: false
                  });
                }
                alertpoly.addTo(alertLayer);
              }
            }
          }
          if (false) {
            stop = leg.from;
            lastStop = leg.to;
            point = {
              y: stop.lat,
              x: stop.lon
            };
            icon = L.divIcon({
              className: "navigator-div-icon"
            });
            label = "<span style='font-size: 24px;'><img src='static/images/" + google_icons[(_ref2 = leg.routeType) != null ? _ref2 : leg.mode] + "' style='vertical-align: sub; height: 24px'/><span>" + leg.route + "</span></span>";
            marker = L.marker(new L.LatLng(point.y, point.x), {
              icon: icon
            }).addTo(routeLayer).bindPopup("<b>Time: " + (moment(leg.startTime).format("HH:mm")) + "&mdash;" + (moment(leg.endTime).format("HH:mm")) + "</b><br /><b>From:</b> " + (stop.name || "") + "<br /><b>To:</b> " + (lastStop.name || ""));
          }
        }
        return {
          route: routeLayer,
          alerts: alertLayer
        };
      };

      TransitMapMixin.prototype.drawItinerary = function(route) {
        var _ref;
        if (this.routeLayer != null) {
          this.clearItinerary();
        }
        _ref = this.createRouteLayerFromItinerary(route.getSelectedItinerary()), this.routeLayer = _ref.route, this.alertLayer = _ref.alerts;
        this.skipMoveend = true;
        this.map.refitAndAddLayer(this.routeLayer);
        return this.map.addLayer(this.alertLayer);
      };

      TransitMapMixin.prototype.clearItinerary = function() {
        if (this.routeLayer) {
          this.map.removeLayer(this.routeLayer);
          this.map.adapt();
        }
        if (this.alertLayer) {
          this.map.removeLayer(this.alertLayer);
        }
        this.routeLayer = null;
        return this.alertLayer = null;
      };

      return TransitMapMixin;

    })();
  });

}).call(this);

//# sourceMappingURL=transit-map.js.map
