(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['underscore', 'moment', 'bootstrap-datetimepicker', 'cs!app/p13n', 'cs!app/models', 'cs!app/search', 'cs!app/views/base', 'cs!app/views/accessibility', 'cs!app/geocoding', 'cs!app/jade'], function(_, moment, datetimepicker, p13n, models, search, base, accessibilityViews, geocoding, jade) {
    var RouteControllersView, RouteSettingsHeaderView, RouteSettingsView, TransportModeControlsView;
    RouteSettingsView = (function(_super) {
      __extends(RouteSettingsView, _super);

      function RouteSettingsView() {
        return RouteSettingsView.__super__.constructor.apply(this, arguments);
      }

      RouteSettingsView.prototype.template = 'route-settings';

      RouteSettingsView.prototype.regions = {
        'headerRegion': '.route-settings-header',
        'routeControllersRegion': '.route-controllers',
        'accessibilitySummaryRegion': '.accessibility-viewpoint-part',
        'transportModeControlsRegion': '.transport_mode_controls'
      };

      RouteSettingsView.prototype.initialize = function(attrs) {
        this.unit = attrs.unit;
        return this.listenTo(this.model, 'change', this.updateRegions);
      };

      RouteSettingsView.prototype.onRender = function() {
        this.headerRegion.show(new RouteSettingsHeaderView({
          model: this.model
        }));
        this.routeControllersRegion.show(new RouteControllersView({
          model: this.model,
          unit: this.unit
        }));
        this.accessibilitySummaryRegion.show(new accessibilityViews.AccessibilityViewpointView({
          filterTransit: true,
          template: 'accessibility-viewpoint-oneline'
        }));
        return this.transportModeControlsRegion.show(new TransportModeControlsView);
      };

      RouteSettingsView.prototype.updateRegions = function() {
        this.headerRegion.currentView.render();
        this.accessibilitySummaryRegion.currentView.render();
        return this.transportModeControlsRegion.currentView.render();
      };

      return RouteSettingsView;

    })(base.SMLayout);
    RouteSettingsHeaderView = (function(_super) {
      __extends(RouteSettingsHeaderView, _super);

      function RouteSettingsHeaderView() {
        return RouteSettingsHeaderView.__super__.constructor.apply(this, arguments);
      }

      RouteSettingsHeaderView.prototype.template = 'route-settings-header';

      RouteSettingsHeaderView.prototype.events = {
        'click .settings-summary': 'toggleSettingsVisibility',
        'click .ok-button': 'toggleSettingsVisibility'
      };

      RouteSettingsHeaderView.prototype.serializeData = function() {
        var mode, origin, originName, profiles, transportIcons, value, _ref;
        profiles = p13n.getAccessibilityProfileIds(true);
        origin = this.model.getOrigin();
        originName = this.model.getEndpointName(origin);
        if (((origin != null ? origin.isDetectedLocation() : void 0) && !(origin != null ? origin.isPending() : void 0)) || ((origin != null) && origin instanceof models.CoordinatePosition)) {
          originName = originName.toLowerCase();
        }
        transportIcons = [];
        _ref = p13n.get('transport');
        for (mode in _ref) {
          value = _ref[mode];
          if (value) {
            transportIcons.push("icon-icon-" + (mode.replace('_', '-')));
          }
        }
        return {
          profile_set: _.keys(profiles).length,
          profiles: p13n.getProfileElements(profiles),
          origin_name: originName,
          origin_is_pending: this.model.getOrigin().isPending(),
          transport_icons: transportIcons
        };
      };

      RouteSettingsHeaderView.prototype.toggleSettingsVisibility = function(event) {
        event.preventDefault();
        $('#route-details').toggleClass('settings-open');
        $('.bootstrap-datetimepicker-widget').hide();
        return $('#route-details').trigger("shown");
      };

      return RouteSettingsHeaderView;

    })(base.SMItemView);
    TransportModeControlsView = (function(_super) {
      __extends(TransportModeControlsView, _super);

      function TransportModeControlsView() {
        this.onRender = __bind(this.onRender, this);
        return TransportModeControlsView.__super__.constructor.apply(this, arguments);
      }

      TransportModeControlsView.prototype.template = 'transport-mode-controls';

      TransportModeControlsView.prototype.events = {
        'click .transport-modes a': 'switchTransportMode'
      };

      TransportModeControlsView.prototype.onRender = function() {
        return _(['public', 'bicycle']).each((function(_this) {
          return function(group) {
            return _this.$el.find("." + group + "-details a").click(function(ev) {
              ev.preventDefault();
              return _this.switchTransportDetails(ev, group);
            });
          };
        })(this));
      };

      TransportModeControlsView.prototype.serializeData = function() {
        var bicycleDetailsClasses, publicModes, selectedValues, transportModes;
        transportModes = p13n.get('transport');
        bicycleDetailsClasses = '';
        if (transportModes.public_transport) {
          bicycleDetailsClasses += 'no-arrow ';
        }
        if (!transportModes.bicycle) {
          bicycleDetailsClasses += 'hidden';
        }
        selectedValues = (function(_this) {
          return function(modes) {
            return _(modes).chain().pairs().filter(function(v) {
              return v[1] === true;
            }).map(function(v) {
              return v[0];
            }).value();
          };
        })(this);
        transportModes = selectedValues(transportModes);
        publicModes = selectedValues(p13n.get('transport_detailed_choices')["public"]);
        return {
          transport_modes: transportModes,
          public_modes: publicModes,
          transport_detailed_choices: p13n.get('transport_detailed_choices'),
          bicycle_details_classes: bicycleDetailsClasses
        };
      };

      TransportModeControlsView.prototype.switchTransportMode = function(ev) {
        var type;
        ev.preventDefault();
        type = $(ev.target).closest('li').data('type');
        return p13n.toggleTransport(type);
      };

      TransportModeControlsView.prototype.switchTransportDetails = function(ev, group) {
        var type;
        ev.preventDefault();
        type = $(ev.target).closest('li').data('type');
        return p13n.toggleTransportDetails(group, type);
      };

      return TransportModeControlsView;

    })(base.SMItemView);
    RouteControllersView = (function(_super) {
      __extends(RouteControllersView, _super);

      function RouteControllersView() {
        return RouteControllersView.__super__.constructor.apply(this, arguments);
      }

      RouteControllersView.prototype.template = 'route-controllers';

      RouteControllersView.prototype.events = {
        'click .preset.unlocked': 'switchToLocationInput',
        'click .preset-current-time': 'switchToTimeInput',
        'click .preset-current-date': 'switchToDateInput',
        'click .time-mode': 'setTimeMode',
        'click .swap-endpoints': 'swapEndpoints',
        'click .tt-suggestion': function(e) {
          return e.stopPropagation();
        },
        'click': 'undoChanges',
        'click .time': function(ev) {
          return ev.stopPropagation();
        },
        'click .date': function(ev) {
          return ev.stopPropagation();
        }
      };

      RouteControllersView.prototype.initialize = function(attrs) {
        window.debugRoutingControls = this;
        this.permanentModel = this.model;
        this.pendingPosition = this.permanentModel.pendingPosition;
        this.currentUnit = attrs.unit;
        return this._reset();
      };

      RouteControllersView.prototype._reset = function() {
        this.stopListening(this.model);
        this.model = this.permanentModel.clone();
        this.listenTo(this.model, 'change', (function(_this) {
          return function(model, options) {
            var _ref, _ref1, _ref2, _ref3;
            if (!(options != null ? options.alreadyVisible : void 0)) {
              if ((_ref = _this.$el.find('input.time').data("DateTimePicker")) != null) {
                _ref.hide();
              }
              if ((_ref1 = _this.$el.find('input.time').data("DateTimePicker")) != null) {
                _ref1.destroy();
              }
              if ((_ref2 = _this.$el.find('input.date').data("DateTimePicker")) != null) {
                _ref2.hide();
              }
              if ((_ref3 = _this.$el.find('input.date').data("DateTimePicker")) != null) {
                _ref3.destroy();
              }
              return _this.render();
            }
          };
        })(this));
        this.listenTo(this.model.getOrigin(), 'change', this.render);
        return this.listenTo(this.model.getDestination(), 'change', this.render);
      };

      RouteControllersView.prototype.onRender = function() {
        this.enableTypeahead('.transit-end input');
        this.enableTypeahead('.transit-start input');
        return this.enableDatetimePicker();
      };

      RouteControllersView.prototype.enableDatetimePicker = function() {
        var closePicker, inputElement, keys, other, otherHider, valueSetter;
        keys = ['time', 'date'];
        other = (function(_this) {
          return function(key) {
            return keys[keys.indexOf(key) + 1 % keys.length];
          };
        })(this);
        inputElement = (function(_this) {
          return function(key) {
            return _this.$el.find("input." + key);
          };
        })(this);
        otherHider = (function(_this) {
          return function(key) {
            return function() {
              var _ref;
              return (_ref = inputElement(other(key)).data("DateTimePicker")) != null ? _ref.hide() : void 0;
            };
          };
        })(this);
        valueSetter = (function(_this) {
          return function(key) {
            return function(ev) {
              var keyUpper;
              keyUpper = key.charAt(0).toUpperCase() + key.slice(1);
              _this.model["set" + keyUpper].call(_this.model, ev.date.toDate(), {
                alreadyVisible: true
              });
              return _this.applyChanges();
            };
          };
        })(this);
        closePicker = true;
        _.each(keys, (function(_this) {
          return function(key) {
            var $input, dateTimePicker, disablePick, options;
            $input = inputElement(key);
            if ($input.length > 0) {
              options = {};
              disablePick = {
                time: 'pickDate',
                date: 'pickTime'
              }[key];
              options[disablePick] = false;
              $input.datetimepicker(options);
              $input.on('dp.show', function() {
                if (_this.activateOnRender !== 'date' && (_this.shown != null) && _this.shown !== key) {
                  closePicker = false;
                }
                otherHider(key)();
                return _this.shown = key;
              });
              $input.on('dp.change', valueSetter(key));
              dateTimePicker = $input.data("DateTimePicker");
              $input.on('click', function() {
                if (closePicker) {
                  _this._closeDatetimePicker($input);
                }
                return closePicker = !closePicker;
              });
              if (_this.activateOnRender === key) {
                dateTimePicker.show();
                return $input.attr('readonly', _this._isScreenHeightLow());
              }
            }
          };
        })(this));
        return this.activateOnRender = null;
      };

      RouteControllersView.prototype.applyChanges = function() {
        this.permanentModel.set(this.model.attributes);
        return this.permanentModel.triggerComplete();
      };

      RouteControllersView.prototype.undoChanges = function() {
        var destination, origin;
        this._reset();
        origin = this.model.getOrigin();
        destination = this.model.getDestination();
        return this.model.trigger('change');
      };

      RouteControllersView.prototype.enableTypeahead = function(selector) {
        var geocoderBackend, options, selectAddress;
        this.$searchEl = this.$el.find(selector);
        if (!this.$searchEl.length) {
          return;
        }
        geocoderBackend = new geocoding.GeocoderSourceBackend();
        options = geocoderBackend.getDatasetOptions();
        options.templates.empty = function(ctx) {
          return jade.template('typeahead-no-results', ctx);
        };
        this.$searchEl.typeahead(null, [options]);
        this.$searchEl.on('keyup', (function(_this) {
          return function(e) {
            if (e.keyCode === 13) {
              return $('.tt-suggestion:first-child').trigger('click');
            }
          };
        })(this));
        selectAddress = (function(_this) {
          return function(event, match) {
            _this.commit = true;
            switch ($(event.currentTarget).attr('data-endpoint')) {
              case 'origin':
                _this.model.setOrigin(match);
                break;
              case 'destination':
                _this.model.setDestination(match);
            }
            return _this.applyChanges();
          };
        })(this);
        geocoderBackend.setOptions({
          $inputEl: this.$searchEl,
          selectionCallback: selectAddress
        });
        return $('#route-details').on("shown", (function(_this) {
          return function() {
            return _this.$searchEl.attr('tabindex', -1).focus();
          };
        })(this));
      };

      RouteControllersView.prototype._locationNameAndLocking = function(object) {
        return {
          name: this.model.getEndpointName(object),
          lock: this.model.getEndpointLocking(object)
        };
      };

      RouteControllersView.prototype._isScreenHeightLow = function() {
        return $(window).innerHeight() < 700;
      };

      RouteControllersView.prototype.serializeData = function() {
        var datetime, today, tomorrow;
        datetime = moment(this.model.getDatetime());
        today = new Date();
        tomorrow = moment(today).add(1, 'days');
        return {
          disable_keyboard: this._isScreenHeightLow(),
          is_today: !this.forceDateInput && datetime.isSame(today, 'day'),
          is_tomorrow: datetime.isSame(tomorrow, 'day'),
          params: this.model,
          origin: this._locationNameAndLocking(this.model.getOrigin()),
          destination: this._locationNameAndLocking(this.model.getDestination()),
          time: datetime.format('LT'),
          date: datetime.format('L'),
          time_mode: this.model.get('time_mode')
        };
      };

      RouteControllersView.prototype.swapEndpoints = function(ev) {
        ev.stopPropagation();
        this.permanentModel.swapEndpoints({
          silent: true
        });
        this.model.swapEndpoints();
        if (this.model.isComplete()) {
          return this.applyChanges();
        }
      };

      RouteControllersView.prototype.switchToLocationInput = function(ev) {
        var position;
        ev.stopPropagation();
        this._reset();
        position = this.pendingPosition;
        position.clear();
        switch ($(ev.currentTarget).attr('data-route-node')) {
          case 'start':
            this.model.setOrigin(position);
            break;
          case 'end':
            this.model.setDestination(position);
        }
        this.listenToOnce(position, 'change', (function(_this) {
          return function() {
            _this.applyChanges();
            return _this.render();
          };
        })(this));
        return position.trigger('request');
      };

      RouteControllersView.prototype.setTimeMode = function(ev) {
        var timeMode;
        ev.stopPropagation();
        timeMode = $(ev.target).data('value');
        if (timeMode !== this.model.get('time_mode')) {
          this.model.setTimeMode(timeMode);
          return this.applyChanges();
        }
      };

      RouteControllersView.prototype._closeDatetimePicker = function($input) {
        return $input.data("DateTimePicker").hide();
      };

      RouteControllersView.prototype.switchToTimeInput = function(ev) {
        ev.stopPropagation();
        this.activateOnRender = 'time';
        return this.model.setDefaultDatetime();
      };

      RouteControllersView.prototype.switchToDateInput = function(ev) {
        ev.stopPropagation();
        this.activateOnRender = 'date';
        this.forceDateInput = true;
        return this.model.trigger('change');
      };

      return RouteControllersView;

    })(base.SMItemView);
    return RouteSettingsView;
  });

}).call(this);

//# sourceMappingURL=route-settings.js.map
