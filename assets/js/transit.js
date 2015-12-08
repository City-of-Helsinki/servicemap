(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['backbone', 'leaflet'], function(Backbone, L) {
    var Route, createWaitLeg, decodePolyline, exports, modeMap, otpCleanup;
    modeMap = {
      tram: 'TRAM',
      bus: 'BUS',
      metro: 'SUBWAY',
      ferry: 'FERRY',
      train: 'RAIL'
    };
    decodePolyline = function(encoded, dims) {
      var b, dim, i, point, points, result, shift;
      point = (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 0; 0 <= dims ? _i < dims : _i > dims; i = 0 <= dims ? ++_i : --_i) {
          _results.push(0);
        }
        return _results;
      })();
      i = 0;
      points = (function() {
        var _i, _results;
        _results = [];
        while (i < encoded.length) {
          for (dim = _i = 0; 0 <= dims ? _i < dims : _i > dims; dim = 0 <= dims ? ++_i : --_i) {
            result = 0;
            shift = 0;
            while (true) {
              b = encoded.charCodeAt(i++) - 63;
              result |= (b & 0x1f) << shift;
              shift += 5;
              if (!(b >= 0x20)) {
                break;
              }
            }
            point[dim] += result & 1 ? ~(result >> 1) : result >> 1;
          }
          _results.push(point.slice(0));
        }
        return _results;
      })();
      return points;
    };
    otpCleanup = function(data) {
      var coords, itinerary, last, leg, legs, length, newLegs, points, time, waitTime, x, _i, _j, _len, _len1, _ref, _ref1, _ref2;
      _ref1 = ((_ref = data.plan) != null ? _ref.itineraries : void 0) || [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        itinerary = _ref1[_i];
        legs = itinerary.legs;
        length = legs.length;
        last = length - 1;
        if (!legs[0].routeType && legs[0].startTime !== itinerary.startTime) {
          legs[0].startTime = itinerary.startTime;
          legs[0].duration = legs[0].endTime - legs[0].startTime;
        }
        if (!legs[last].routeType && legs[last].endTime !== itinerary.endTime) {
          legs[last].endTime = itinerary.endTime;
          legs[last].duration = legs[last].endTime - legs[last].startTime;
        }
        newLegs = [];
        time = itinerary.startTime;
        _ref2 = itinerary.legs;
        for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
          leg = _ref2[_j];
          points = decodePolyline(leg.legGeometry.points, 2);
          points = (function() {
            var _k, _len2, _results;
            _results = [];
            for (_k = 0, _len2 = points.length; _k < _len2; _k++) {
              coords = points[_k];
              _results.push((function() {
                var _l, _len3, _results1;
                _results1 = [];
                for (_l = 0, _len3 = coords.length; _l < _len3; _l++) {
                  x = coords[_l];
                  _results1.push(x * 1e-5);
                }
                return _results1;
              })());
            }
            return _results;
          })();
          leg.legGeometry.points = points;
          if (leg.startTime - time > 1000 && leg.routeType === null) {
            waitTime = leg.startTime - time;
            time = leg.endTime;
            leg.startTime -= waitTime;
            leg.endTime -= waitTime;
            newLegs.push(leg);
            newLegs.push(createWaitLeg(leg.endTime, waitTime, _.last(leg.legGeometry.points), leg.to.name));
          } else if (leg.startTime - time > 1000) {
            waitTime = leg.startTime - time;
            time = leg.endTime;
            newLegs.push(createWaitLeg(leg.startTime - waitTime, waitTime, leg.legGeometry.points[0], leg.from.name));
            newLegs.push(leg);
          } else {
            newLegs.push(leg);
            time = leg.endTime;
          }
        }
        itinerary.legs = newLegs;
      }
      return data;
    };
    createWaitLeg = function(startTime, duration, point, placename) {
      var leg;
      leg = {
        mode: "WAIT",
        routeType: null,
        route: "",
        duration: duration,
        startTime: startTime,
        endTime: startTime + duration,
        legGeometry: {
          points: [point]
        },
        from: {
          lat: point[0],
          lon: point[1],
          name: placename
        }
      };
      leg.to = leg.from;
      return leg;
    };
    Route = (function(_super) {
      __extends(Route, _super);

      function Route() {
        return Route.__super__.constructor.apply(this, arguments);
      }

      Route.prototype.initialize = function() {
        this.set('selected_itinerary', 0);
        this.set('plan', null);
        return this.listenTo(this, 'change:selected_itinerary', (function(_this) {
          return function() {
            return _this.trigger('change:plan', _this);
          };
        })(this));
      };

      Route.prototype.abort = function() {
        if (!this.xhr) {
          return;
        }
        this.xhr.abort();
        return this.xhr = null;
      };

      Route.prototype.requestPlan = function(from, to, opts) {
        var args, data, modes;
        opts = opts || {};
        if (this.xhr) {
          this.xhr.abort();
          this.xhr = null;
        }
        modes = ['WALK'];
        if (opts.bicycle) {
          modes = ['BICYCLE'];
        }
        if (opts.car) {
          if (opts.transit) {
            modes = ['CAR_PARK', 'WALK'];
          } else {
            modes = ['CAR'];
          }
        }
        if (opts.transit) {
          modes.push('TRANSIT');
        } else {
          modes = _.union(modes, _(opts.modes).map((function(_this) {
            return function(m) {
              return modeMap[m];
            };
          })(this)));
        }
        data = {
          fromPlace: from,
          toPlace: to,
          mode: modes.join(','),
          numItineraries: 3,
          showIntermediateStops: 'true',
          locale: p13n.getLanguage()
        };
        if (opts.wheelchair) {
          data.wheelchair = true;
        }
        if (opts.walkReluctance) {
          data.walkReluctance = opts.walkReluctance;
        }
        if (opts.walkBoardCost) {
          data.walkBoardCost = opts.walkBoardCost;
        }
        if (opts.walkSpeed) {
          data.walkSpeed = opts.walkSpeed;
        }
        if (opts.minTransferTime) {
          data.minTransferTime = opts.minTransferTime;
        }
        if (opts.date && opts.time) {
          data.date = opts.date;
          data.time = opts.time;
        }
        if (opts.arriveBy) {
          data.arriveBy = true;
        }
        args = {
          dataType: 'json',
          url: appSettings.otp_backend,
          data: data,
          success: (function(_this) {
            return function(data) {
              _this.xhr = null;
              if ('error' in data) {
                _this.trigger('error');
                return;
              }
              data = otpCleanup(data);
              _this.set('selected_itinerary', 0);
              return _this.set('plan', data.plan);
            };
          })(this),
          error: (function(_this) {
            return function() {
              _this.clear();
              return _this.trigger('error');
            };
          })(this)
        };
        return this.xhr = $.ajax(args);
      };

      Route.prototype.getSelectedItinerary = function() {
        return this.get('plan').itineraries[this.get('selected_itinerary')];
      };

      Route.prototype.clear = function() {
        return this.set('plan', null);
      };

      return Route;

    })(Backbone.Model);
    return exports = {
      Route: Route
    };
  });

}).call(this);

//# sourceMappingURL=transit.js.map
