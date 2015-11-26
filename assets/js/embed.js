(function() {
  var PAGE_SIZE, requirejsConfig,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  requirejsConfig = {
    baseUrl: appSettings.static_path + 'vendor',
    paths: {
      app: '../js'
    },
    shim: {
      bootstrap: {
        deps: ['jquery']
      },
      backbone: {
        deps: ['underscore', 'jquery'],
        exports: 'Backbone'
      },
      'leaflet.markercluster': {
        deps: ['leaflet']
      },
      'iexhr': {
        deps: ['jquery']
      }
    },
    config: {
      'cs!app/p13n': {
        localStorageEnabled: false
      }
    }
  };

  requirejs.config(requirejsConfig);

  PAGE_SIZE = 1000;

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

  requirejs(['cs!app/models', 'cs!app/p13n', 'cs!app/color', 'cs!app/map-base-view', 'cs!app/map', 'cs!app/views/embedded-title', 'backbone', 'backbone.marionette', 'jquery', 'iexhr', 'i18next', 'URI', 'bootstrap', 'cs!app/router', 'cs!app/control', 'cs!app/embedded-views', 'cs!app/widgets'], function(models, p13n, ColorMatcher, BaseMapView, map, TitleView, Backbone, Marionette, $, iexhr, i18n, URI, Bootstrap, Router, BaseControl, TitleBarView, widgets) {
    var EmbeddedMapView, app, appState, fullUrl;
    app = new Backbone.Marionette.Application();
    window.app = app;
    fullUrl = function() {
      var currentUri;
      currentUri = URI(window.location.href);
      return currentUri.segment(0, "").toString();
    };
    EmbeddedMapView = (function(_super) {
      __extends(EmbeddedMapView, _super);

      function EmbeddedMapView() {
        return EmbeddedMapView.__super__.constructor.apply(this, arguments);
      }

      EmbeddedMapView.prototype.mapOptions = {
        dragging: true,
        touchZoom: true,
        scrollWheelZoom: false,
        doubleClickZoom: true,
        boxZoom: false
      };

      EmbeddedMapView.prototype.postInitialize = function() {
        var logo, zoom;
        EmbeddedMapView.__super__.postInitialize.call(this);
        zoom = L.control.zoom({
          position: 'bottomright',
          zoomInText: "<span class=\"icon-icon-zoom-in\"></span>",
          zoomOutText: "<span class=\"icon-icon-zoom-out\"></span>"
        });
        logo = new widgets.ControlWrapper(new TitleView({
          href: fullUrl()
        }), {
          position: 'bottomleft',
          autoZIndex: false
        });
        zoom.addTo(this.map);
        logo.addTo(this.map);
        this.allMarkers.on('click', (function(_this) {
          return function(l) {
            var root, _ref;
            root = URI(window.location.href).host();
            if (((_ref = l.layer) != null ? _ref.unit : void 0) != null) {
              return window.open(("http://" + root + "/unit/") + l.layer.unit.get('id'));
            } else {
              return window.open(fullUrl());
            }
          };
        })(this));
        return this.allMarkers.on('clusterclick', (function(_this) {
          return function() {
            return window.open(fullUrl());
          };
        })(this));
      };

      EmbeddedMapView.prototype.clusterPopup = function(event) {
        var childCount, cluster, html, popup;
        cluster = event.layer;
        childCount = cluster.getChildCount();
        popup = this.createPopup();
        html = "<div class='servicemap-prompt'>\n    " + (i18n.t('embed.click_prompt_move')) + "\n</div>";
        popup.setContent(html);
        popup.setLatLng(cluster.getBounds().getCenter());
        return popup;
      };

      EmbeddedMapView.prototype.createPopup = function(unit) {
        var htmlContent, popup;
        popup = L.popup({
          offset: L.point(0, 30),
          closeButton: false
        });
        if (unit != null) {
          htmlContent = "<div class='unit-name'>" + (unit.getText('name')) + "</div>\n<div class='servicemap-prompt'>" + (i18n.t('embed.click_prompt')) + "</div>";
          popup.setContent(htmlContent);
        }
        return popup;
      };

      EmbeddedMapView.prototype.getFeatureGroup = function() {
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
          zoomToBoundsOnClick: false
        });
      };

      EmbeddedMapView.prototype.handlePosition = function(positionObject) {
        var accuracy, latLng, marker, name, popup;
        accuracy = location.accuracy;
        latLng = map.MapUtils.latLngFromGeojson(positionObject);
        marker = map.MapUtils.createPositionMarker(latLng, accuracy, positionObject.origin(), {
          clickable: true
        });
        marker.position = positionObject;
        popup = L.popup({
          offset: L.point(0, 40),
          closeButton: false
        });
        name = positionObject.humanAddress();
        popup.setContent("<div class='unit-name'>" + name + "</div>");
        marker.bindPopup(popup);
        marker.addTo(this.map);
        this.map.adapt();
        marker.openPopup();
        return marker.on('click', (function(_this) {
          return function() {
            return window.open(fullUrl());
          };
        })(this));
      };

      return EmbeddedMapView;

    })(BaseMapView);
    appState = {
      divisions: new models.AdministrativeDivisionList,
      units: new models.UnitList(null, {
        pageSize: 500
      }),
      selectedUnits: new models.UnitList(),
      selectedPosition: new models.WrappedModel(),
      selectedDivision: new models.WrappedModel(),
      selectedServices: new models.ServiceList(),
      searchResults: new models.SearchList([], {
        pageSize: appSettings.page_size
      })
    };
    appState.services = appState.selectedServices;
    window.appState = appState;
    app.addInitializer(function(opts) {
      var baseRoot, control, currentUri, root, rootRegexp, router, url;
      this.colorMatcher = new ColorMatcher;
      control = new BaseControl(appState);
      router = new Router({
        controller: control,
        makeMapView: (function(_this) {
          return function(mapOptions) {
            var mapView;
            mapView = new EmbeddedMapView(appState, mapOptions, true);
            app.getRegion('map').show(mapView);
            return control.setMapProxy(mapView.getProxy());
          };
        })(this)
      });
      baseRoot = "" + appSettings.url_prefix + "embed";
      root = baseRoot + '/';
      if (!(window.history && history.pushState)) {
        rootRegexp = new RegExp(baseRoot + '\/?');
        url = window.location.href;
        url = url.replace(rootRegexp, '/');
        currentUri = URI(url);
        currentUri;
        router.routeEmbedded(currentUri);
      } else {
        Backbone.history.start({
          pushState: true,
          root: root
        });
      }
      return this.commands.setHandler('addUnitsWithinBoundingBoxes', (function(_this) {
        return function(bboxes) {
          return control.addUnitsWithinBoundingBoxes(bboxes);
        };
      })(this));
    });
    app.addRegions({
      navigation: '#navigation-region',
      map: '#app-container'
    });
    return $.when(p13n.deferred).done(function() {
      var $appContainer;
      app.start();
      $appContainer = $('#app-container');
      $appContainer.attr('class', p13n.get('map_background_layer'));
      return $appContainer.addClass('embed');
    });
  });

}).call(this);

//# sourceMappingURL=embed.js.map
