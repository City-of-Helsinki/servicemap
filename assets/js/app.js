(function() {
  var DEBUG_STATE, VERIFY_INVARIANTS, config,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  requirejs(['leaflet'], function(L) {
    return L.Map.prototype._originalGetBounds = L.Map.prototype.getBounds;
  });

  DEBUG_STATE = appSettings.debug_state;

  VERIFY_INVARIANTS = appSettings.verify_invariants;

  window.getIeVersion = function() {
    var isInternetExplorer, matches;
    isInternetExplorer = function() {
      return window.navigator.appName === "Microsoft Internet Explorer";
    };
    if (!isInternetExplorer()) {
      return false;
    }
    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec(window.navigator.userAgent);
    return parseInt(matches[1]);
  };

  if (appSettings.sentry_url) {
    config = {};
    if (appSettings.sentry_disable) {
      config.shouldSendCallback = function() {
        return false;
      };
    }
    requirejs(['raven'], function(Raven) {
      Raven.config(appSettings.sentry_url, config).install();
      return Raven.setExtraContext({
        gitCommit: appSettings.git_commit_id
      });
    });
  } else {
    requirejs(['raven'], function(Raven) {
      return Raven.debug = false;
    });
  }

  requirejs(['cs!app/models', 'cs!app/p13n', 'cs!app/map-view', 'cs!app/landing', 'cs!app/color', 'cs!app/tour', 'backbone', 'backbone.marionette', 'jquery', 'i18next', 'cs!app/uservoice', 'cs!app/transit', 'cs!app/debug', 'iexhr', 'cs!app/views/service-cart', 'cs!app/views/navigation', 'cs!app/views/personalisation', 'cs!app/views/language-selector', 'cs!app/views/title', 'cs!app/views/feedback-form', 'cs!app/views/feedback-confirmation', 'cs!app/views/feature-tour-start', 'cs!app/views/service-map-disclaimers', 'cs!app/views/exporting', 'cs!app/base', 'cs!app/widgets', 'cs!app/control', 'cs!app/router'], function(Models, p13n, MapView, landingPage, ColorMatcher, tour, Backbone, Marionette, $, i18n, uservoice, transit, debug, iexhr, ServiceCartView, NavigationLayout, PersonalisationView, LanguageSelectorView, titleViews, FeedbackFormView, FeedbackConfirmationView, TourStartButton, disclaimers, ExportingView, sm, widgets, BaseControl, BaseRouter) {
    var AppControl, AppRouter, LOG, app, appModels, cachedMapView, isFrontPage, makeMapView, setSiteTitle;
    LOG = debug.log;
    isFrontPage = (function(_this) {
      return function() {
        return Backbone.history.fragment === '';
      };
    })(this);
    AppControl = (function(_super) {
      __extends(AppControl, _super);

      function AppControl() {
        return AppControl.__super__.constructor.apply(this, arguments);
      }

      AppControl.prototype.initialize = function(appModels) {
        AppControl.__super__.initialize.call(this, appModels);
        this.route = appModels.route;
        this.selectedEvents = appModels.selectedEvents;
        this._resetPendingFeedback(appModels.pendingFeedback);
        this.listenTo(p13n, 'change', function(path, val) {
          if (path[path.length - 1] === 'city') {
            return this._reFetchAllServiceUnits();
          }
        });
        if (DEBUG_STATE) {
          return this.eventDebugger = new debug.EventDebugger(appModels);
        }
      };

      AppControl.prototype._resetPendingFeedback = function(o) {
        if (o != null) {
          this.pendingFeedback = o;
        } else {
          this.pendingFeedback = new Models.FeedbackMessage();
        }
        appModels.pendingFeedback = this.pendingFeedback;
        return this.listenTo(appModels.pendingFeedback, 'sent', (function(_this) {
          return function() {
            return app.getRegion('feedbackFormContainer').show(new FeedbackConfirmationView(appModels.pendingFeedback.get('unit')));
          };
        })(this));
      };

      AppControl.prototype.atMostOneIsSet = function(list) {
        return _.filter(list, function(o) {
          return o.isSet();
        }).length <= 1;
      };

      AppControl.prototype._verifyInvariants = function() {
        if (!this.atMostOneIsSet([this.services, this.searchResults])) {
          return new Error("Active services and search results are mutually exclusive.");
        }
        if (!this.atMostOneIsSet([this.selectedPosition, this.selectedUnits])) {
          return new Error("Selected positions/units/events are mutually exclusive.");
        }
        if (!this.atMostOneIsSet([this.searchResults, this.selectedPosition])) {
          return new Error("Search results & selected position are mutually exclusive.");
        }
        return null;
      };

      AppControl.prototype.reset = function() {
        this._setSelectedUnits();
        this._clearRadius();
        this.selectedPosition.clear();
        this.selectedDivision.clear();
        this.route.clear();
        this.units.reset([]);
        this.services.reset([], {
          silent: true
        });
        this.selectedEvents.reset([]);
        return this._resetSearchResults();
      };

      AppControl.prototype.isStateEmpty = function() {
        return this.selectedPosition.isEmpty() && this.services.isEmpty() && this.selectedEvents.isEmpty();
      };

      AppControl.prototype._resetSearchResults = function() {
        this.searchResults.query = null;
        this.searchResults.reset([]);
        if (this.selectedUnits.isSet()) {
          return this.units.reset([this.selectedUnits.first()]);
        } else if (!this.units.isEmpty()) {
          return this.units.reset();
        }
      };

      AppControl.prototype.clearUnits = function(opts) {
        var resetOpts;
        this.route.clear();
        if (this.searchResults.isSet()) {
          return;
        }
        if (opts != null ? opts.all : void 0) {
          this.units.clearFilters();
          this.units.reset([], {
            bbox: true
          });
          return;
        }
        if (this.services.isSet()) {
          return;
        }
        if (this.selectedPosition.isSet() && 'distance' in this.units.filters) {
          return;
        }
        if ((opts != null ? opts.bbox : void 0) === false && 'bbox' in this.units.filters) {
          return;
        } else if ((opts != null ? opts.bbox : void 0) && !('bbox' in this.units.filters)) {
          return;
        }
        this.units.clearFilters();
        resetOpts = {
          bbox: opts != null ? opts.bbox : void 0
        };
        if (opts.silent) {
          resetOpts.silent = true;
        }
        if (opts != null ? opts.bbox : void 0) {
          resetOpts.noRefit = true;
        }
        if (this.selectedUnits.isSet()) {
          return this.units.reset([this.selectedUnits.first()], resetOpts);
        } else {
          return this.units.reset([], resetOpts);
        }
      };

      AppControl.prototype.highlightUnit = function(unit) {
        return this.units.trigger('unit:highlight', unit);
      };

      AppControl.prototype.clearFilters = function() {
        return this.units.clearFilters();
      };

      AppControl.prototype.clearSelectedUnit = function() {
        this.route.clear();
        this.selectedUnits.each(function(u) {
          return u.set('selected', false);
        });
        this._setSelectedUnits();
        this.clearUnits({
          all: false,
          bbox: false
        });
        return sm.resolveImmediately();
      };

      AppControl.prototype.selectEvent = function(event) {
        var select, unit;
        this._clearRadius();
        unit = event.getUnit();
        select = (function(_this) {
          return function() {
            event.set('unit', unit);
            if (unit != null) {
              _this.setUnit(unit);
            }
            return _this.selectedEvents.reset([event]);
          };
        })(this);
        if (unit != null) {
          return unit.fetch({
            success: select
          });
        } else {
          return select();
        }
      };

      AppControl.prototype.clearSelectedPosition = function() {
        this.selectedDivision.clear();
        this.selectedPosition.clear();
        return sm.resolveImmediately();
      };

      AppControl.prototype.resetPosition = function(position) {
        if (position == null) {
          position = this.selectedPosition.value();
          if (position == null) {
            position = new models.CoordinatePosition({
              isDetected: true
            });
          }
        }
        position.clear();
        this.listenToOnce(p13n, 'position', (function(_this) {
          return function(position) {
            return _this.selectPosition(position);
          };
        })(this));
        return p13n.requestLocation(position);
      };

      AppControl.prototype.clearSelectedEvent = function() {
        this._clearRadius();
        return this.selectedEvents.set([]);
      };

      AppControl.prototype.removeUnit = function(unit) {
        this.units.remove(unit);
        if (unit === this.selectedUnits.first()) {
          return this.clearSelectedUnit();
        }
      };

      AppControl.prototype.removeUnits = function(units) {
        this.units.remove(units, {
          silent: true
        });
        return this.units.trigger('batch-remove', {
          removed: units
        });
      };

      AppControl.prototype._clearRadius = function() {
        var hasFilter, pos;
        pos = this.selectedPosition.value();
        if (pos != null) {
          hasFilter = pos.get('radiusFilter');
          if (hasFilter != null) {
            pos.set('radiusFilter', null);
            return this.units.reset([]);
          }
        }
      };

      AppControl.prototype._reFetchAllServiceUnits = function() {
        if (this.services.length > 0) {
          this.units.reset([]);
          return this.services.each((function(_this) {
            return function(s) {
              return _this._fetchServiceUnits(s);
            };
          })(this));
        }
      };

      AppControl.prototype.removeService = function(serviceId) {
        var otherServices, service, unitsToRemove;
        service = this.services.get(serviceId);
        this.services.remove(service);
        if (service.get('units') == null) {
          return;
        }
        otherServices = this.services.filter((function(_this) {
          return function(s) {
            return s !== service;
          };
        })(this));
        unitsToRemove = service.get('units').reject((function(_this) {
          return function(unit) {
            return (_this.selectedUnits.get(unit) != null) || _(otherServices).find(function(s) {
              return s.get('units').get(unit) != null;
            });
          };
        })(this));
        this.removeUnits(unitsToRemove);
        if (this.services.size() === 0) {
          if (this.selectedPosition.isSet()) {
            this.selectPosition(this.selectedPosition.value());
            this.selectedPosition.trigger('change:value', this.selectedPosition, this.selectedPosition.value());
          }
        }
        return sm.resolveImmediately();
      };

      AppControl.prototype.clearSearchResults = function() {
        this.searchResults.query = null;
        if (!this.searchResults.isEmpty()) {
          this._resetSearchResults();
        }
        return sm.resolveImmediately();
      };

      AppControl.prototype.closeSearch = function() {
        if (this.isStateEmpty()) {
          this.home();
        }
        return sm.resolveImmediately();
      };

      AppControl.prototype.composeFeedback = function(unit) {
        app.getRegion('feedbackFormContainer').show(new FeedbackFormView({
          model: this.pendingFeedback,
          unit: unit
        }));
        $('#feedback-form-container').on('shown.bs.modal', function() {
          return $(this).children().attr('tabindex', -1).focus();
        });
        return $('#feedback-form-container').modal('show');
      };

      AppControl.prototype.closeFeedback = function() {
        this._resetPendingFeedback();
        return _.defer((function(_this) {
          return function() {
            return app.getRegion('feedbackFormContainer').reset();
          };
        })(this));
      };

      AppControl.prototype.showServiceMapDescription = function() {
        app.getRegion('feedbackFormContainer').show(new disclaimers.ServiceMapDisclaimersView());
        return $('#feedback-form-container').modal('show');
      };

      AppControl.prototype.home = function() {
        return this.reset();
      };

      return AppControl;

    })(BaseControl);
    app = new Marionette.Application();
    appModels = {
      services: new Models.ServiceList(),
      selectedServices: new Models.ServiceList(),
      units: new Models.UnitList(null, {
        setComparator: true
      }),
      selectedUnits: new Models.UnitList(),
      selectedEvents: new Models.EventList(),
      searchResults: new Models.SearchList([], {
        pageSize: appSettings.page_size
      }),
      searchState: new Models.WrappedModel(),
      route: new transit.Route(),
      routingParameters: new Models.RoutingParameters(),
      selectedPosition: new Models.WrappedModel(),
      selectedDivision: new Models.WrappedModel(),
      divisions: new models.AdministrativeDivisionList,
      pendingFeedback: new Models.FeedbackMessage()
    };
    cachedMapView = null;
    makeMapView = function(mapOpts) {
      var f, map, opts, pos;
      if (!cachedMapView) {
        opts = {
          units: appModels.units,
          services: appModels.selectedServices,
          selectedUnits: appModels.selectedUnits,
          searchResults: appModels.searchResults,
          selectedPosition: appModels.selectedPosition,
          selectedDivision: appModels.selectedDivision,
          route: appModels.route,
          divisions: appModels.divisions
        };
        cachedMapView = new MapView(opts, mapOpts);
        window.mapView = cachedMapView;
        map = cachedMapView.map;
        pos = appModels.routingParameters.pendingPosition;
        pos.on('request', (function(_this) {
          return function(ev) {
            return cachedMapView.requestLocation(pos);
          };
        })(this));
        app.getRegion('map').show(cachedMapView);
        f = function() {
          return landingPage.clear();
        };
        cachedMapView.map.addOneTimeEventListener({
          'zoomstart': f,
          'mousedown': f
        });
        app.commands.execute('setMapProxy', cachedMapView.getProxy());
      }
      return cachedMapView;
    };
    setSiteTitle = function(routeTitle) {
      var title;
      title = "" + (i18n.t('general.site_title'));
      if (routeTitle) {
        title = ("" + (p13n.getTranslatedAttr(routeTitle)) + " | ") + title;
      }
      return $('head title').text(title);
    };
    AppRouter = (function(_super) {
      __extends(AppRouter, _super);

      function AppRouter() {
        return AppRouter.__super__.constructor.apply(this, arguments);
      }

      AppRouter.prototype.initialize = function(options) {
        var blank, refreshServices;
        AppRouter.__super__.initialize.call(this, options);
        this.appModels = options.models;
        refreshServices = (function(_this) {
          return function() {
            var ids;
            ids = _this.appModels.selectedServices.pluck('id').join(',');
            if (ids.length) {
              return "unit?service=" + ids;
            } else {
              if (_this.appModels.selectedPosition.isSet()) {
                return _this.fragmentFunctions.selectPosition();
              } else {
                return "";
              }
            }
          };
        })(this);
        blank = (function(_this) {
          return function() {
            return "";
          };
        })(this);
        return this.fragmentFunctions = {
          selectUnit: (function(_this) {
            return function() {
              var id;
              id = _this.appModels.selectedUnits.first().id;
              return "unit/" + id;
            };
          })(this),
          search: (function(_this) {
            return function(params) {
              var query;
              query = params[0];
              return "search?q=" + query;
            };
          })(this),
          selectPosition: (function(_this) {
            return function() {
              var slug;
              slug = _this.appModels.selectedPosition.value().slugifyAddress();
              return "address/" + slug;
            };
          })(this),
          addService: refreshServices,
          removeService: refreshServices,
          clearSelectedPosition: blank,
          clearSelectedUnit: blank,
          clearSearchResults: blank,
          closeSearch: blank,
          home: blank
        };
      };

      AppRouter.prototype._getFragment = function(commandString, parameters) {
        var _base;
        return typeof (_base = this.fragmentFunctions)[commandString] === "function" ? _base[commandString](parameters) : void 0;
      };

      AppRouter.prototype.navigateByCommand = function(commandString, parameters) {
        var fragment;
        fragment = this._getFragment(commandString, parameters);
        if (fragment != null) {
          this.navigate(fragment);
          return p13n.trigger('url');
        }
      };

      AppRouter.prototype.onPostRouteExecute = function() {
        if (isFrontPage() && !p13n.get('skip_tour') && !p13n.get('hide_tour')) {
          return tour.startTour();
        }
      };

      return AppRouter;

    })(BaseRouter);
    app.addRegions({
      navigation: '#navigation-region',
      personalisation: '#personalisation',
      exporting: '#exporting',
      languageSelector: '#language-selector',
      serviceCart: '#service-cart',
      landingLogo: '#landing-logo',
      logo: '#persistent-logo',
      map: '#app-container',
      tourStart: '#feature-tour-start',
      feedbackFormContainer: '#feedback-form-container',
      disclaimerContainer: '#disclaimers'
    });
    app.addInitializer(function(opts) {
      var COMMANDS, appControl, comm, commandInterceptor, exportingView, f, languageSelector, makeInterceptor, navigation, personalisation, reportError, router, serviceCart, showButton, _i, _len;
      window.debugAppModels = appModels;
      appModels.services.fetch({
        data: {
          level: 0
        }
      });
      appControl = new AppControl(appModels);
      router = new AppRouter({
        models: appModels,
        controller: appControl,
        makeMapView: makeMapView
      });
      appControl.router = router;
      COMMANDS = ["addService", "removeService", "selectUnit", "highlightUnit", "clearSelectedUnit", "selectPosition", "clearSelectedPosition", "resetPosition", "selectEvent", "clearSelectedEvent", "toggleDivision", "clearFilters", "setUnits", "setUnit", "addUnitsWithinBoundingBoxes", "search", "clearSearchResults", "closeSearch", "setRadiusFilter", "home", "composeFeedback", "closeFeedback", "hideTour", "showServiceMapDescription", "setMapProxy"];
      reportError = function(position, command) {
        var e, message;
        e = appControl._verifyInvariants();
        if (e) {
          message = "Invariant failed " + position + " command " + command + ": " + e.message;
          LOG(appModels);
          e.message = message;
          throw e;
        }
      };
      commandInterceptor = function(comm, parameters) {
        var _ref;
        return (_ref = appControl[comm].apply(appControl, parameters)) != null ? typeof _ref.done === "function" ? _ref.done((function(_this) {
          return function() {
            var _ref1;
            if (((_ref1 = parameters[0]) != null ? _ref1.navigate : void 0) !== false) {
              return router.navigateByCommand(comm, parameters);
            }
          };
        })(this)) : void 0 : void 0;
      };
      makeInterceptor = function(comm) {
        if (DEBUG_STATE) {
          return function() {
            LOG("COMMAND " + comm + " CALLED");
            commandInterceptor(comm, arguments);
            return LOG(appModels);
          };
        } else if (VERIFY_INVARIANTS) {
          return function() {
            LOG("COMMAND " + comm + " CALLED");
            reportError("before", comm);
            commandInterceptor(comm, arguments);
            return reportError("after", comm);
          };
        } else {
          return function() {
            return commandInterceptor(comm, arguments);
          };
        }
      };
      for (_i = 0, _len = COMMANDS.length; _i < _len; _i++) {
        comm = COMMANDS[_i];
        this.commands.setHandler(comm, makeInterceptor(comm));
      }
      navigation = new NavigationLayout({
        serviceTreeCollection: appModels.services,
        selectedServices: appModels.selectedServices,
        searchResults: appModels.searchResults,
        selectedUnits: appModels.selectedUnits,
        selectedEvents: appModels.selectedEvents,
        searchState: appModels.searchState,
        route: appModels.route,
        units: appModels.units,
        routingParameters: appModels.routingParameters,
        selectedPosition: appModels.selectedPosition
      });
      this.getRegion('navigation').show(navigation);
      this.getRegion('landingLogo').show(new titleViews.LandingTitleView);
      this.getRegion('logo').show(new titleViews.TitleView);
      personalisation = new PersonalisationView;
      this.getRegion('personalisation').show(personalisation);
      exportingView = new ExportingView();
      this.getRegion('exporting').show(exportingView);
      languageSelector = new LanguageSelectorView({
        p13n: p13n
      });
      this.getRegion('languageSelector').show(languageSelector);
      serviceCart = new ServiceCartView({
        collection: appModels.selectedServices
      });
      this.getRegion('serviceCart').show(serviceCart);
      this.colorMatcher = new ColorMatcher(appModels.selectedServices);
      f = function() {
        return landingPage.clear();
      };
      $('body').one("keydown", f);
      $('body').one("click", f);
      Backbone.history.start({
        pushState: true,
        root: appSettings.url_prefix
      });
      $('body').on('click', 'a', function(ev) {
        var target;
        target = $(ev.currentTarget);
        if (!target.hasClass('external-link') && !target.hasClass('force')) {
          return ev.preventDefault();
        }
      });
      this.listenTo(app.vent, 'site-title:change', setSiteTitle);
      showButton = (function(_this) {
        return function() {
          var tourButtonView;
          tourButtonView = new TourStartButton();
          app.getRegion('tourStart').show(tourButtonView);
          return _this.listenToOnce(tourButtonView, 'close', function() {
            return app.getRegion('tourStart').reset();
          });
        };
      })(this);
      if (p13n.get('skip_tour')) {
        showButton();
      }
      this.listenTo(p13n, 'tour-skipped', (function(_this) {
        return function() {
          return showButton();
        };
      })(this));
      return app.getRegion('disclaimerContainer').show(new disclaimers.ServiceMapDisclaimersOverlayView);
    });
    app.addInitializer(widgets.initializer);
    window.app = app;
    return $.when(p13n.deferred).done(function() {
      $('html').attr('lang', p13n.getLanguage());
      app.start();
      if (isFrontPage()) {
        if (p13n.get('first_visit')) {
          $('body').addClass('landing');
        }
      }
      $('#app-container').attr('class', p13n.get('map_background_layer'));
      p13n.setVisited();
      return uservoice.init(p13n.getLanguage());
    });
  });

}).call(this);

//# sourceMappingURL=app.js.map
