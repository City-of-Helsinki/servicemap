(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['underscore', 'moment', 'i18next', 'cs!app/p13n', 'cs!app/models', 'cs!app/spinner', 'cs!app/views/base', 'cs!app/views/route-settings'], function(_, moment, i18n, p13n, models, SMSpinner, base, RouteSettingsView) {
    var RouteView, RoutingSummaryView;
    RouteView = (function(_super) {
      __extends(RouteView, _super);

      function RouteView() {
        return RouteView.__super__.constructor.apply(this, arguments);
      }

      RouteView.prototype.id = 'route-view-container';

      RouteView.prototype.className = 'route-view';

      RouteView.prototype.template = 'route';

      RouteView.prototype.regions = {
        'routeSettingsRegion': '.route-settings',
        'routeSummaryRegion': '.route-summary'
      };

      RouteView.prototype.events = {
        'click a.collapser.route': 'toggleRoute',
        'click .show-map': 'showMap'
      };

      RouteView.prototype.initialize = function(options) {
        this.parentView = options.parentView;
        this.selectedUnits = options.selectedUnits;
        this.selectedPosition = options.selectedPosition;
        this.route = options.route;
        this.routingParameters = options.routingParameters;
        this.listenTo(this.routingParameters, 'complete', _.debounce(_.bind(this.requestRoute, this), 300));
        this.listenTo(p13n, 'change', this.changeTransitIcon);
        this.listenTo(this.route, 'change:plan', (function(_this) {
          return function(route) {
            if (route.has('plan')) {
              _this.routingParameters.set('route', _this.route);
              return _this.showRouteSummary(_this.route);
            }
          };
        })(this));
        return this.listenTo(p13n, 'change', (function(_this) {
          return function(path, val) {
            return _this.requestRoute();
          };
        })(this));
      };

      RouteView.prototype.serializeData = function() {
        return {
          transit_icon: this.getTransitIcon()
        };
      };

      RouteView.prototype.getTransitIcon = function() {
        var mode, modeIconName, setModes;
        setModes = _.filter(_.pairs(p13n.get('transport')), function(_arg) {
          var k, v;
          k = _arg[0], v = _arg[1];
          return v === true;
        });
        mode = setModes.pop()[0];
        modeIconName = mode.replace('_', '-');
        return "icon-icon-" + modeIconName;
      };

      RouteView.prototype.changeTransitIcon = function() {
        var $iconEl;
        $iconEl = this.$el.find('#route-section-icon');
        return $iconEl.removeClass().addClass(this.getTransitIcon());
      };

      RouteView.prototype.toggleRoute = function(ev) {
        var $element;
        $element = $(ev.currentTarget);
        if ($element.hasClass('collapsed')) {
          return this.showRoute();
        } else {
          return this.hideRoute();
        }
      };

      RouteView.prototype.showMap = function(ev) {
        return this.parentView.showMap(ev);
      };

      RouteView.prototype.showRoute = function() {
        var lastPos, previousOrigin;
        lastPos = p13n.getLastPosition();
        this.routingParameters.ensureUnitDestination();
        this.routingParameters.setDestination(this.model);
        previousOrigin = this.routingParameters.getOrigin();
        if (lastPos) {
          if (!previousOrigin) {
            this.routingParameters.setOrigin(lastPos, {
              silent: true
            });
          }
          this.requestRoute();
        } else {
          this.listenTo(p13n, 'position', (function(_this) {
            return function(pos) {
              return _this.requestRoute();
            };
          })(this));
          this.listenTo(p13n, 'position_error', (function(_this) {
            return function() {
              return _this.showRouteSummary(null);
            };
          })(this));
          if (!previousOrigin) {
            this.routingParameters.setOrigin(new models.CoordinatePosition);
          }
          p13n.requestLocation(this.routingParameters.getOrigin());
        }
        this.routeSettingsRegion.show(new RouteSettingsView({
          model: this.routingParameters,
          unit: this.model
        }));
        return this.showRouteSummary(null);
      };

      RouteView.prototype.showRouteSummary = function(route) {
        return this.routeSummaryRegion.show(new RoutingSummaryView({
          model: this.routingParameters,
          noRoute: route == null
        }));
      };

      RouteView.prototype.requestRoute = function() {
        var datetime, from, opts, publicTransportChoices, selectedVehicles, spinner, to;
        if (!this.routingParameters.isComplete()) {
          return;
        }
        spinner = new SMSpinner({
          container: this.$el.find('#route-details .route-spinner').get(0)
        });
        spinner.start();
        this.listenTo(this.route, 'change:plan', (function(_this) {
          return function(plan) {
            return spinner.stop();
          };
        })(this));
        this.listenTo(this.route, 'error', (function(_this) {
          return function() {
            return spinner.stop();
          };
        })(this));
        this.routingParameters.unset('route');
        opts = {};
        if (p13n.getAccessibilityMode('mobility') === 'wheelchair') {
          opts.wheelchair = true;
          opts.walkReluctance = 5;
          opts.walkBoardCost = 12 * 60;
          opts.walkSpeed = 0.75;
          opts.minTransferTime = 3 * 60 + 1;
        }
        if (p13n.getAccessibilityMode('mobility') === 'reduced_mobility') {
          opts.walkReluctance = 5;
          opts.walkBoardCost = 10 * 60;
          opts.walkSpeed = 0.5;
        }
        if (p13n.getAccessibilityMode('mobility') === 'rollator') {
          opts.wheelchair = true;
          opts.walkReluctance = 5;
          opts.walkSpeed = 0.5;
          opts.walkBoardCost = 12 * 60;
        }
        if (p13n.getAccessibilityMode('mobility') === 'stroller') {
          opts.walkBoardCost = 10 * 60;
          opts.walkSpeed = 1;
        }
        if (p13n.getTransport('bicycle')) {
          opts.bicycle = true;
        }
        if (p13n.getTransport('car')) {
          opts.car = true;
        }
        if (p13n.getTransport('public_transport')) {
          publicTransportChoices = p13n.get('transport_detailed_choices')["public"];
          selectedVehicles = _(publicTransportChoices).chain().pairs().filter(_.last).map(_.first).value();
          if (selectedVehicles.length === _(publicTransportChoices).values().length) {
            opts.transit = true;
          } else {
            opts.transit = false;
            opts.modes = selectedVehicles;
          }
        }
        datetime = this.routingParameters.getDatetime();
        opts.date = moment(datetime).format('YYYY/MM/DD');
        opts.time = moment(datetime).format('HH:mm');
        opts.arriveBy = this.routingParameters.get('time_mode') === 'arrive';
        from = this.routingParameters.getOrigin().otpSerializeLocation({
          forceCoordinates: opts.car
        });
        to = this.routingParameters.getDestination().otpSerializeLocation({
          forceCoordinates: opts.car
        });
        return this.route.requestPlan(from, to, opts);
      };

      RouteView.prototype.hideRoute = function() {
        return this.route.clear();
      };

      return RouteView;

    })(base.SMLayout);
    RoutingSummaryView = (function(_super) {
      var LEG_MODES, MODES_WITH_STOPS, NUMBER_OF_CHOICES_SHOWN;

      __extends(RoutingSummaryView, _super);

      function RoutingSummaryView() {
        return RoutingSummaryView.__super__.constructor.apply(this, arguments);
      }

      RoutingSummaryView.prototype.template = 'routing-summary';

      RoutingSummaryView.prototype.className = 'route-summary';

      RoutingSummaryView.prototype.events = {
        'click .route-selector a': 'switchItinerary',
        'click .accessibility-viewpoint': 'setAccessibility'
      };

      RoutingSummaryView.prototype.initialize = function(options) {
        this.itineraryChoicesStartIndex = 0;
        this.detailsOpen = false;
        this.skipRoute = options.noRoute;
        return this.route = this.model.get('route');
      };

      NUMBER_OF_CHOICES_SHOWN = 3;

      LEG_MODES = {
        WALK: {
          icon: 'icon-icon-by-foot',
          colorClass: 'transit-walk',
          text: i18n.t('transit.walk')
        },
        BUS: {
          icon: 'icon-icon-bus',
          colorClass: 'transit-default',
          text: i18n.t('transit.bus')
        },
        BICYCLE: {
          icon: 'icon-icon-bicycle',
          colorClass: 'transit-bicycle',
          text: i18n.t('transit.bicycle')
        },
        CAR: {
          icon: 'icon-icon-car',
          colorClass: 'transit-car',
          text: i18n.t('transit.car')
        },
        TRAM: {
          icon: 'icon-icon-tram',
          colorClass: 'transit-tram',
          text: i18n.t('transit.tram')
        },
        SUBWAY: {
          icon: 'icon-icon-subway',
          colorClass: 'transit-subway',
          text: i18n.t('transit.subway')
        },
        RAIL: {
          icon: 'icon-icon-train',
          colorClass: 'transit-rail',
          text: i18n.t('transit.rail')
        },
        FERRY: {
          icon: 'icon-icon-ferry',
          colorClass: 'transit-ferry',
          text: i18n.t('transit.ferry')
        },
        WAIT: {
          icon: '',
          colorClass: 'transit-default',
          text: i18n.t('transit.wait')
        }
      };

      MODES_WITH_STOPS = ['BUS', 'FERRY', 'RAIL', 'SUBWAY', 'TRAM'];

      RoutingSummaryView.prototype.serializeData = function() {
        var choices, end, filteredLegs, itinerary, legs, mobilityAccessibilityMode, mobilityElement, route;
        if (this.skipRoute) {
          return {
            skip_route: true
          };
        }
        window.debugRoute = this.route;
        itinerary = this.route.getSelectedItinerary();
        filteredLegs = _.filter(itinerary.legs, function(leg) {
          return leg.mode !== 'WAIT';
        });
        mobilityAccessibilityMode = p13n.getAccessibilityMode('mobility');
        mobilityElement = null;
        if (mobilityAccessibilityMode) {
          mobilityElement = p13n.getProfileElement(mobilityAccessibilityMode);
        } else {
          mobilityElement = LEG_MODES['WALK'];
        }
        legs = _.map(filteredLegs, (function(_this) {
          return function(leg) {
            var icon, startLocation, steps, text;
            steps = _this.parseSteps(leg);
            if (leg.mode === 'WALK') {
              icon = mobilityElement.icon;
              if (mobilityAccessibilityMode === 'wheelchair') {
                text = i18n.t('transit.mobility_mode.wheelchair');
              } else {
                text = i18n.t('transit.walk');
              }
            } else {
              icon = LEG_MODES[leg.mode].icon;
              text = LEG_MODES[leg.mode].text;
            }
            if (leg.from.bogusName) {
              startLocation = i18n.t("otp.bogus_name." + (leg.from.name.replace(' ', '_')));
            }
            return {
              start_time: moment(leg.startTime).format('LT'),
              start_location: startLocation || p13n.getTranslatedAttr(leg.from.translatedName) || leg.from.name,
              distance: _this.getLegDistance(leg, steps),
              icon: icon,
              transit_color_class: LEG_MODES[leg.mode].colorClass,
              transit_mode: text,
              route: _this.getRouteText(leg),
              transit_destination: _this.getTransitDestination(leg),
              steps: steps,
              has_warnings: !!_.find(steps, function(step) {
                return step.warning;
              })
            };
          };
        })(this));
        end = {
          time: moment(itinerary.endTime).format('LT'),
          name: p13n.getTranslatedAttr(this.route.get('plan').to.translatedName) || this.route.get('plan').to.name,
          address: p13n.getTranslatedAttr(this.model.getDestination().get('street_address'))
        };
        route = {
          duration: Math.round(itinerary.duration / 60) + ' min',
          walk_distance: (itinerary.walkDistance / 1000).toFixed(1) + 'km',
          legs: legs,
          end: end
        };
        choices = this.getItineraryChoices();
        return {
          skip_route: false,
          profile_set: _.keys(p13n.getAccessibilityProfileIds(true)).length,
          itinerary: route,
          itinerary_choices: choices,
          selected_itinerary_index: this.route.get('selected_itinerary'),
          details_open: this.detailsOpen,
          current_time: moment(new Date()).format('YYYY-MM-DDTHH:mm')
        };
      };

      RoutingSummaryView.prototype.parseSteps = function(leg) {
        var alert, step, steps, stop, text, warning, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;
        steps = [];
        if ((_ref = leg.mode) === 'WALK' || _ref === 'BICYCLE' || _ref === 'CAR') {
          _ref1 = leg.steps;
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            step = _ref1[_i];
            warning = null;
            if (step.bogusName) {
              step.streetName = i18n.t("otp.bogus_name." + (step.streetName.replace(' ', '_')));
            } else if (p13n.getTranslatedAttr(step.translatedName)) {
              step.streetName = p13n.getTranslatedAttr(step.translatedName);
            }
            text = i18n.t("otp.step_directions." + step.relativeDirection, {
              street: step.streetName,
              postProcess: "fixFinnishStreetNames"
            });
            if ('alerts' in step && step.alerts.length) {
              warning = step.alerts[0].alertHeaderText.someTranslation;
            }
            steps.push({
              text: text,
              warning: warning
            });
          }
        } else if ((_ref2 = leg.mode, __indexOf.call(MODES_WITH_STOPS, _ref2) >= 0) && leg.intermediateStops) {
          if ('alerts' in leg && leg.alerts.length) {
            _ref3 = leg.alerts;
            for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
              alert = _ref3[_j];
              steps.push({
                text: "",
                warning: alert.alertHeaderText.someTranslation
              });
            }
          }
          _ref4 = leg.intermediateStops;
          for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
            stop = _ref4[_k];
            steps.push({
              text: p13n.getTranslatedAttr(stop.translatedName) || stop.name,
              time: moment(stop.arrival).format('LT')
            });
          }
        } else {
          steps.push({
            text: 'No further info.'
          });
        }
        return steps;
      };

      RoutingSummaryView.prototype.getLegDistance = function(leg, steps) {
        var stops, _ref;
        if (_ref = leg.mode, __indexOf.call(MODES_WITH_STOPS, _ref) >= 0) {
          stops = _.reject(steps, function(step) {
            return 'warning' in step;
          });
          return "" + stops.length + " " + (i18n.t('transit.stops'));
        } else {
          return (leg.distance / 1000).toFixed(1) + 'km';
        }
      };

      RoutingSummaryView.prototype.getTransitDestination = function(leg) {
        var _ref;
        if (_ref = leg.mode, __indexOf.call(MODES_WITH_STOPS, _ref) >= 0) {
          return "" + (i18n.t('transit.toward')) + " " + leg.headsign;
        } else {
          return '';
        }
      };

      RoutingSummaryView.prototype.getRouteText = function(leg) {
        var route;
        route = leg.route.length < 5 ? leg.route : '';
        if (leg.mode === 'FERRY') {
          route = '';
        }
        return route;
      };

      RoutingSummaryView.prototype.getItineraryChoices = function() {
        var numberOfItineraries, start, stop;
        numberOfItineraries = this.route.get('plan').itineraries.length;
        start = this.itineraryChoicesStartIndex;
        stop = Math.min(start + NUMBER_OF_CHOICES_SHOWN, numberOfItineraries);
        return _.range(start, stop);
      };

      RoutingSummaryView.prototype.switchItinerary = function(event) {
        event.preventDefault();
        this.detailsOpen = true;
        this.route.set('selected_itinerary', $(event.currentTarget).data('index'));
        return this.render();
      };

      RoutingSummaryView.prototype.setAccessibility = function(event) {
        event.preventDefault();
        return p13n.trigger('user:open');
      };

      return RoutingSummaryView;

    })(base.SMItemView);
    return RouteView;
  });

}).call(this);

//# sourceMappingURL=route.js.map
