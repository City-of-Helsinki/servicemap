(function() {
  define(['leaflet', 'proj4leaflet', 'underscore', 'cs!app/base'], function(leaflet, p4j, _, sm) {
    var MapMaker, MapUtils, RETINA_MODE, SMap, getMaxBounds, makeDistanceComparator, makeLayer, wmtsPath;
    RETINA_MODE = window.devicePixelRatio > 1;
    getMaxBounds = function(layer) {
      return L.latLngBounds(L.latLng(59.5, 24.2), L.latLng(60.5, 25.5));
    };
    wmtsPath = function(style, language) {
      var path, stylePath;
      stylePath = style === 'accessible_map' ? language === 'sv' ? "osm-sm-visual-sv/etrs_tm35fin" : "osm-sm-visual/etrs_tm35fin" : RETINA_MODE ? language === 'sv' ? "osm-sm-sv-hq/etrs_tm35fin_hq" : "osm-sm-hq/etrs_tm35fin_hq" : language === 'sv' ? "osm-sm-sv/etrs_tm35fin" : "osm-sm/etrs_tm35fin";
      path = ["http://geoserver.hel.fi/mapproxy/wmts", stylePath, "{z}/{x}/{y}.png"];
      return path.join('/');
    };
    makeLayer = {
      tm35: {
        crs: function() {
          var bounds, crsName, crsOpts, originNw, projDef;
          crsName = 'EPSG:3067';
          projDef = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs';
          bounds = L.bounds(L.point(-548576, 6291456), L.point(1548576, 8388608));
          originNw = [bounds.min.x, bounds.max.y];
          crsOpts = {
            resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125],
            bounds: bounds,
            transformation: new L.Transformation(1, -originNw[0], -1, originNw[1])
          };
          return new L.Proj.CRS(crsName, projDef, crsOpts);
        },
        layer: function(opts) {
          return L.tileLayer(wmtsPath(opts.style, opts.language), {
            maxZoom: 15,
            minZoom: 6,
            continuousWorld: true,
            tms: false
          });
        }
      },
      gk25: {
        crs: function() {
          var bounds, crsName, projDef;
          crsName = 'EPSG:3879';
          projDef = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs';
          bounds = [25440000, 6630000, 25571072, 6761072];
          return new L.Proj.CRS.TMS(crsName, projDef, bounds, {
            resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625, 0.03125]
          });
        },
        layer: function(opts) {
          var geoserverUrl, guideMapOptions, guideMapUrl;
          geoserverUrl = function(layerName, layerFmt) {
            return "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/" + layerName + "@ETRS-GK25@" + layerFmt + "/{z}/{x}/{y}." + layerFmt;
          };
          if (opts.style === 'ortographic') {
            return new L.Proj.TileLayer.TMS(geoserverUrl("hel:orto2013", "jpg"), opts.crs, {
              maxZoom: 10,
              minZoom: 2,
              continuousWorld: true,
              tms: false
            });
          } else {
            guideMapUrl = geoserverUrl("hel:Karttasarja", "gif");
            guideMapOptions = {
              maxZoom: 12,
              minZoom: 2,
              continuousWorld: true,
              tms: false
            };
            return (new L.Proj.TileLayer.TMS(guideMapUrl, opts.crs, guideMapOptions)).setOpacity(0.8);
          }
        }
      }
    };
    SMap = L.Map.extend({
      refitAndAddLayer: function(layer) {
        this.mapState.adaptToLayer(layer);
        return this.addLayer(layer);
      },
      refitAndAddMarker: function(marker) {
        this.mapState.adaptToLatLngs([marker.getLatLng()]);
        return this.addLayer(marker);
      },
      adaptToLatLngs: function(latLngs) {
        return this.mapState.adaptToLatLngs(latLngs);
      },
      adapt: function() {
        return this.mapState.adaptToBounds(null);
      }
    });
    MapMaker = (function() {
      function MapMaker() {}

      MapMaker.makeBackgroundLayer = function(options) {
        var coordinateSystem, crs, layerMaker, tileLayer;
        coordinateSystem = (function() {
          switch (options.style) {
            case 'guidemap':
              return 'gk25';
            case 'ortographic':
              return 'gk25';
            default:
              return 'tm35';
          }
        })();
        layerMaker = makeLayer[coordinateSystem];
        crs = layerMaker.crs();
        options.crs = crs;
        tileLayer = layerMaker.layer(options);
        tileLayer.on('tileload', (function(_this) {
          return function(e) {
            return e.tile.setAttribute('alt', '');
          };
        })(this));
        return {
          layer: tileLayer,
          crs: crs
        };
      };

      MapMaker.createMap = function(domElement, options, mapOptions, mapState) {
        var crs, defaultMapOptions, layer, map, _ref;
        _ref = MapMaker.makeBackgroundLayer(options), layer = _ref.layer, crs = _ref.crs;
        defaultMapOptions = {
          crs: crs,
          continuusWorld: true,
          worldCopyJump: false,
          zoomControl: false,
          closePopupOnClick: false,
          maxBounds: getMaxBounds(options.style),
          layers: [layer]
        };
        _.extend(defaultMapOptions, mapOptions);
        map = new SMap(domElement, defaultMapOptions);
        if (mapState != null) {
          mapState.setMap(map);
        }
        map.crs = crs;
        map._baseLayer = layer;
        return map;
      };

      return MapMaker;

    })();
    MapUtils = (function() {
      function MapUtils() {}

      MapUtils.createPositionMarker = function(latLng, accuracy, type, opts) {
        var Z_INDEX, marker;
        Z_INDEX = -1000;
        switch (type) {
          case 'detected':
            opts = {
              icon: L.divIcon({
                iconSize: L.point(40, 40),
                iconAnchor: L.point(20, 39),
                className: 'servicemap-div-icon',
                html: '<span class="icon-icon-you-are-here"></span'
              }),
              zIndexOffset: Z_INDEX
            };
            marker = L.marker(latLng, opts);
            break;
          case 'clicked':
            marker = L.circleMarker(latLng, {
              color: '#666',
              weight: 2,
              opacity: 1,
              fill: false,
              clickable: (opts != null ? opts.clickable : void 0) != null ? opts.clickable : false,
              zIndexOffset: Z_INDEX
            });
            marker.setRadius(6);
            break;
          case 'address':
            opts = {
              zIndexOffset: Z_INDEX,
              icon: L.divIcon({
                iconSize: L.point(40, 40),
                iconAnchor: L.point(20, 39),
                className: 'servicemap-div-icon',
                html: '<span class="icon-icon-address"></span'
              })
            };
            marker = L.marker(latLng, opts);
        }
        return marker;
      };

      MapUtils.overlappingBoundingBoxes = function(map) {
        var DEBUG_GRID, METER_GRID, bbox, bboxes, coordinates, crs, dim, latLngBounds, max, min, ne, nes, pairs, snapToGrid, sw, sws, value, x, y, _i, _j, _k, _len, _len1, _ref, _ref1, _ref2;
        crs = map.crs;
        if (map._originalGetBounds != null) {
          latLngBounds = map._originalGetBounds();
        } else {
          latLngBounds = map.getBounds();
        }
        METER_GRID = 1000;
        DEBUG_GRID = false;
        ne = crs.project(latLngBounds.getNorthEast());
        sw = crs.project(latLngBounds.getSouthWest());
        min = {
          x: ne.x,
          y: sw.y
        };
        max = {
          y: ne.y,
          x: sw.x
        };
        snapToGrid = function(coord) {
          return parseInt(coord / METER_GRID) * METER_GRID;
        };
        coordinates = {};
        _ref = ['x', 'y'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          dim = _ref[_i];
          coordinates[dim] = coordinates[dim] || {};
          for (value = _j = _ref1 = min[dim], _ref2 = max[dim]; _ref1 <= _ref2 ? _j <= _ref2 : _j >= _ref2; value = _ref1 <= _ref2 ? ++_j : --_j) {
            coordinates[dim][parseInt(snapToGrid(value))] = true;
          }
        }
        pairs = _.flatten((function() {
          var _k, _len1, _ref3, _results;
          _ref3 = _.keys(coordinates.y);
          _results = [];
          for (_k = 0, _len1 = _ref3.length; _k < _len1; _k++) {
            y = _ref3[_k];
            _results.push((function() {
              var _l, _len2, _ref4, _results1;
              _ref4 = _.keys(coordinates.x);
              _results1 = [];
              for (_l = 0, _len2 = _ref4.length; _l < _len2; _l++) {
                x = _ref4[_l];
                _results1.push([parseInt(x), parseInt(y)]);
              }
              return _results1;
            })());
          }
          return _results;
        })(), true);
        bboxes = _.map(pairs, function(_arg) {
          var x, y;
          x = _arg[0], y = _arg[1];
          return [[x, y], [x + METER_GRID, y + METER_GRID]];
        });
        if (DEBUG_GRID) {
          this.debugGrid.clearLayers();
          for (_k = 0, _len1 = bboxes.length; _k < _len1; _k++) {
            bbox = bboxes[_k];
            sw = crs.projection.unproject(L.point.apply(L, bbox[0]));
            ne = crs.projection.unproject(L.point.apply(L, bbox[1]));
            sws = [sw.lat, sw.lng].join();
            nes = [ne.lat, ne.lng].join();
            if (!this.debugCircles[sws]) {
              this.debugGrid.addLayer(L.circle(sw, 10));
              this.debugCircles[sws] = true;
            }
            if (!this.debugCircles[nes]) {
              this.debugGrid.addLayer(L.circle(ne, 10));
              this.debugCircles[nes] = true;
            }
          }
        }
        return bboxes;
      };

      MapUtils.latLngFromGeojson = function(object) {
        var _ref, _ref1;
        return L.latLng(object != null ? (_ref = object.get('location')) != null ? (_ref1 = _ref.coordinates) != null ? _ref1.slice(0).reverse() : void 0 : void 0 : void 0);
      };

      MapUtils.getZoomlevelToShowAllMarkers = function() {
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

      return MapUtils;

    })();
    makeDistanceComparator = (function(_this) {
      return function(p13n) {
        var createFrom, position;
        createFrom = function(position) {
          return function(obj) {
            var a, b, result, _ref;
            _ref = [MapUtils.latLngFromGeojson(position), MapUtils.latLngFromGeojson(obj)], a = _ref[0], b = _ref[1];
            result = a.distanceTo(b);
            return result;
          };
        };
        position = p13n.getLastPosition();
        if (position != null) {
          return createFrom(position);
        }
      };
    })(this);
    return {
      MapMaker: MapMaker,
      MapUtils: MapUtils,
      makeDistanceComparator: makeDistanceComparator
    };
  });

}).call(this);

//# sourceMappingURL=map.js.map
