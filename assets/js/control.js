(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['jquery', 'backbone.marionette', 'cs!app/base', 'cs!app/models'], function($, Marionette, sm, Models) {
    var BaseControl, PAGE_SIZE;
    PAGE_SIZE = appSettings.page_size;
    return BaseControl = (function(_super) {
      __extends(BaseControl, _super);

      function BaseControl() {
        this.toggleDivision = __bind(this.toggleDivision, this);
        return BaseControl.__super__.constructor.apply(this, arguments);
      }

      BaseControl.prototype.initialize = function(appModels) {
        this.units = appModels.units;
        this.services = appModels.selectedServices;
        this.selectedUnits = appModels.selectedUnits;
        this.selectedPosition = appModels.selectedPosition;
        this.searchResults = appModels.searchResults;
        this.divisions = appModels.divisions;
        return this.selectedDivision = appModels.selectedDivision;
      };

      BaseControl.prototype.setMapProxy = function(mapProxy) {
        this.mapProxy = mapProxy;
      };

      BaseControl.prototype.setUnits = function(units, filter) {
        this.services.set([]);
        this._setSelectedUnits();
        this.units.reset(units.toArray());
        if (filter != null) {
          return this.units.setFilter(filter, true);
        } else {
          return this.units.clearFilters();
        }
      };

      BaseControl.prototype.setUnit = function(unit) {
        this.services.set([]);
        return this.units.reset([unit]);
      };

      BaseControl.prototype.getUnit = function(id) {
        return this.units.get(id);
      };

      BaseControl.prototype._setSelectedUnits = function(units, options) {
        this.selectedUnits.each(function(u) {
          return u.set('selected', false);
        });
        if (units != null) {
          _(units).each(function(u) {
            return u.set('selected', true);
          });
          return this.selectedUnits.reset(units, options);
        } else {
          if (this.selectedUnits.length) {
            return this.selectedUnits.reset([], options);
          }
        }
      };

      BaseControl.prototype.selectUnit = function(unit, opts) {
        var hasObject, requiredObjects;
        this.selectedDivision.clear();
        if (typeof this._setSelectedUnits === "function") {
          this._setSelectedUnits([unit], {
            silent: true
          });
        }
        if (opts != null ? opts.replace : void 0) {
          this.units.reset([unit]);
          this.units.clearFilters();
        } else if (!this.units.contains(unit)) {
          this.units.add(unit);
          this.units.trigger('reset', this.units);
        }
        hasObject = function(unit, key) {
          var o;
          o = unit.get(key);
          return (o != null) && typeof o === 'object';
        };
        requiredObjects = ['department', 'municipality', 'services'];
        if (!_(requiredObjects).find(function(x) {
          return !hasObject(unit, x);
        })) {
          this.selectedUnits.trigger('reset', this.selectedUnits);
          return sm.resolveImmediately();
        } else {
          return unit.fetch({
            data: {
              include: 'department,municipality,services'
            },
            success: (function(_this) {
              return function() {
                return _this.selectedUnits.trigger('reset', _this.selectedUnits);
              };
            })(this)
          });
        }
      };

      BaseControl.prototype.addUnitsWithinBoundingBoxes = function(bboxStrings, level) {
        var bboxCount, getBbox, _ref;
        if (level === 'none') {
          return;
        }
        if (level == null) {
          level = 'customer_service';
        }
        bboxCount = bboxStrings.length;
        if (bboxCount > 4) {
          null;
        }
        if (((_ref = this.selectedPosition.value()) != null ? _ref.get('radiusFilter') : void 0) != null) {
          return;
        }
        this.units.clearFilters();
        getBbox = (function(_this) {
          return function(bboxStrings) {
            var bboxString, layer, opts, unitList;
            if (bboxStrings.length === 0) {
              _this.units.setFilter('bbox', true);
              _this.units.trigger('finished', {
                keepViewport: true
              });
              return;
            }
            bboxString = _.first(bboxStrings);
            unitList = new models.UnitList(null, {
              forcedPriority: false
            });
            opts = {
              success: function(coll, resp, options) {
                if (unitList.length) {
                  _this.units.add(unitList.toArray());
                }
                if (!unitList.fetchNext(opts)) {
                  return unitList.trigger('finished', {
                    keepViewport: true
                  });
                }
              }
            };
            unitList.pageSize = PAGE_SIZE;
            unitList.setFilter('bbox', bboxString);
            layer = p13n.get('map_background_layer');
            unitList.setFilter('bbox_srid', layer === 'servicemap' || layer === 'accessible_map' ? 3067 : 3879);
            unitList.setFilter('only', 'name,location,root_services');
            if (level != null) {
              unitList.setFilter('level', level);
            }
            _this.listenTo(unitList, 'finished', function() {
              return getBbox(_.rest(bboxStrings));
            });
            return unitList.fetch(opts);
          };
        })(this);
        return getBbox(bboxStrings);
      };

      BaseControl.prototype._clearRadius = function() {};

      BaseControl.prototype.clearSearchResults = function() {};

      BaseControl.prototype.clearUnits = function() {};

      BaseControl.prototype.reset = function() {};

      BaseControl.prototype.toggleDivision = function(division) {
        var old;
        this._clearRadius();
        old = this.selectedDivision.value();
        if (old != null) {
          old.set('selected', false);
        }
        if (division === old) {
          return this.selectedDivision.clear();
        } else {
          this.selectedDivision.wrap(division);
          return division.set('selected', true);
        }
      };

      BaseControl.prototype.renderUnitById = function(id) {
        var deferred, unit;
        deferred = $.Deferred();
        unit = new Models.Unit({
          id: id
        });
        unit.fetch({
          data: {
            include: 'department,municipality,services'
          },
          success: (function(_this) {
            return function() {
              _this.setUnit(unit);
              _this.selectUnit(unit);
              return deferred.resolve(unit);
            };
          })(this)
        });
        return deferred.promise();
      };

      BaseControl.prototype.selectPosition = function(position) {
        var previous;
        if (typeof this.clearSearchResults === "function") {
          this.clearSearchResults();
        }
        if (typeof this._setSelectedUnits === "function") {
          this._setSelectedUnits();
        }
        previous = this.selectedPosition.value();
        if ((previous != null ? previous.get('radiusFilter') : void 0) != null) {
          this.units.reset([]);
          this.units.clearFilters();
        }
        if (position === previous) {
          this.selectedPosition.trigger('change:value', this.selectedPosition);
        } else {
          this.selectedPosition.wrap(position);
        }
        return sm.resolveImmediately();
      };

      BaseControl.prototype.setRadiusFilter = function(radius) {
        var opts, pos, unitList;
        this.services.reset([], {
          skip_navigate: true
        });
        this.units.reset([]);
        this.units.clearFilters();
        this.units.overrideComparatorKeys = ['distance_precalculated', 'alphabetic', 'alphabetic_reverse'];
        this.units.setComparator('distance_precalculated');
        if (this.selectedPosition.isEmpty()) {
          return;
        }
        pos = this.selectedPosition.value();
        pos.set('radiusFilter', radius);
        unitList = new models.UnitList([], {
          pageSize: PAGE_SIZE
        }).setFilter('only', 'name,location,root_services').setFilter('include', 'services,accessibility_properties').setFilter('lat', pos.get('location').coordinates[1]).setFilter('lon', pos.get('location').coordinates[0]).setFilter('distance', radius);
        opts = {
          success: (function(_this) {
            return function() {
              _this.units.add(unitList.toArray(), {
                merge: true
              });
              _this.units.setFilter('distance', radius);
              if (!unitList.fetchNext(opts)) {
                return _this.units.trigger('finished', {
                  refit: true
                });
              }
            };
          })(this)
        };
        return unitList.fetch(opts);
      };

      BaseControl.prototype._addService = function(service) {
        var ancestor;
        this._clearRadius();
        this._setSelectedUnits();
        this.services.add(service);
        if (this.services.length === 1) {
          this.units.reset([]);
          this.units.clearFilters();
          this.units.setDefaultComparator();
          this.clearSearchResults();
        }
        if (service.has('ancestors')) {
          ancestor = this.services.find(function(s) {
            var _ref;
            return _ref = s.id, __indexOf.call(service.get('ancestors'), _ref) >= 0;
          });
          if (ancestor != null) {
            this.removeService(ancestor);
          }
        }
        return this._fetchServiceUnits(service);
      };

      BaseControl.prototype._fetchServiceUnits = function(service) {
        var municipality, opts, unitList;
        unitList = new models.UnitList([], {
          pageSize: PAGE_SIZE,
          setComparator: true
        }).setFilter('service', service.id).setFilter('only', 'name,location,root_services').setFilter('include', 'services,accessibility_properties');
        municipality = p13n.get('city');
        if (municipality) {
          unitList.setFilter('municipality', municipality);
        }
        opts = {
          success: (function(_this) {
            return function() {
              _this.units.add(unitList.toArray(), {
                merge: true
              });
              service.get('units').add(unitList.toArray());
              if (!unitList.fetchNext(opts)) {
                _this.units.overrideComparatorKeys = ['alphabetic', 'alphabetic_reverse', 'distance'];
                _this.units.setDefaultComparator();
                _this.units.trigger('finished', {
                  refit: true
                });
                return service.get('units').trigger('finished');
              }
            };
          })(this)
        };
        return unitList.fetch(opts);
      };

      BaseControl.prototype.addService = function(service) {
        if (service.has('ancestors')) {
          return this._addService(service);
        } else {
          return sm.withDeferred((function(_this) {
            return function(deferred) {
              return service.fetch({
                data: {
                  include: 'ancestors'
                },
                success: function() {
                  return _this._addService(service).done(function() {
                    return deferred.resolve();
                  });
                }
              });
            };
          })(this));
        }
      };

      BaseControl.prototype._search = function(query) {
        this._clearRadius();
        this.selectedPosition.clear();
        this.clearUnits({
          all: true
        });
        return sm.withDeferred((function(_this) {
          return function(deferred) {
            var opts;
            if (_this.searchResults.query === query) {
              _this.searchResults.trigger('ready');
              deferred.resolve();
              return;
            }
            if (__indexOf.call(_(_this.units.filters).keys(), 'search') >= 0) {
              _this.units.reset([]);
            }
            if (!_this.searchResults.isEmpty()) {
              _this.searchResults.reset([]);
            }
            opts = {
              success: function() {
                if (typeof _paq !== "undefined" && _paq !== null) {
                  _paq.push(['trackSiteSearch', query, false, _this.searchResults.models.length]);
                }
                _this.units.add(_this.searchResults.filter(function(r) {
                  return r.get('object_type') === 'unit';
                }));
                _this.units.setFilter('search', true);
                if (!_this.searchResults.fetchNext(opts)) {
                  _this.searchResults.trigger('ready');
                  _this.units.trigger('finished');
                  _this.services.set([]);
                  return deferred.resolve();
                }
              }
            };
            return opts = _this.searchResults.search(query, opts);
          };
        })(this));
      };

      BaseControl.prototype.search = function(query) {
        if (query == null) {
          query = this.searchResults.query;
        }
        if ((query != null) && query.length > 0) {
          return this._search(query);
        } else {
          return sm.resolveImmediately();
        }
      };

      BaseControl.prototype.renderUnitsByServices = function(serviceIdString) {
        var deferreds, serviceIds;
        serviceIds = serviceIdString.split(',');
        deferreds = _.map(serviceIds, (function(_this) {
          return function(id) {
            return _this.addService(new models.Service({
              id: id
            }));
          };
        })(this));
        return $.when.apply($, deferreds);
      };

      BaseControl.prototype._fetchDivisions = function(divisionIds, callback) {
        return this.divisions.setFilter('ocd_id', divisionIds.join(',')).setFilter('geometry', true).fetch({
          success: callback
        });
      };

      BaseControl.prototype._getLevel = function(context, defaultLevel) {
        var _ref;
        if (defaultLevel == null) {
          defaultLevel = 'none';
        }
        return (context != null ? (_ref = context.query) != null ? _ref.level : void 0 : void 0) || defaultLevel;
      };

      BaseControl.prototype._renderDivisions = function(ocdIds, context) {
        var defaultLevel, level;
        level = this._getLevel(context, defaultLevel = 'none');
        return sm.withDeferred((function(_this) {
          return function(deferred) {
            return _this._fetchDivisions(ocdIds, function() {
              var opts;
              if (level === 'none') {
                deferred.resolve();
                return;
              }
              if (level !== 'all') {
                _this.units.setFilter('level', context.query.level);
              }
              _this.units.setFilter('division', ocdIds.join(',')).setFilter('only', ['root_services', 'location', 'name'].join(','));
              opts = {
                success: function() {
                  if (!_this.units.fetchNext(opts)) {
                    _this.units.trigger('finished');
                    return deferred.resolve();
                  }
                }
              };
              _this.units.fetch(opts);
              return _this.units;
            });
          };
        })(this));
      };

      BaseControl.prototype.renderDivision = function(municipality, divisionId, context) {
        return this._renderDivisions(["" + municipality + "/" + divisionId], context);
      };

      BaseControl.prototype.renderMultipleDivisions = function(_path, context) {
        if (context.query.ocdId.length > 0) {
          return this._renderDivisions(context.query.ocdId, context);
        }
      };

      BaseControl.prototype.renderAddress = function(municipality, street, numberPart, context) {
        var defaultLevel, level;
        level = this._getLevel(context, defaultLevel = 'none');
        return sm.withDeferred((function(_this) {
          return function(deferred) {
            var SEPARATOR, positionList, slug;
            SEPARATOR = /-/g;
            slug = "" + municipality + "/" + street + "/" + numberPart;
            positionList = models.PositionList.fromSlug(municipality, street, numberPart);
            return _this.listenTo(positionList, 'sync', function(p) {
              var addressInfo, err, exactMatch, position;
              try {
                if (p.length === 0) {
                  throw new Error('Address slug not found', slug);
                } else if (p.length === 1) {
                  position = p.pop();
                } else if (p.length > 1) {
                  exactMatch = p.filter(function(pos) {
                    var letter, letterMatch, numberEndMatch, numberParts, number_end;
                    numberParts = numberPart.split(SEPARATOR);
                    letter = pos.get('letter');
                    number_end = pos.get('number_end');
                    if (numberParts.length === 1) {
                      return letter === null && number_end === null;
                    }
                    letterMatch = function() {
                      return letter && letter.toLowerCase() === numberParts[1].toLowerCase();
                    };
                    numberEndMatch = function() {
                      return number_end && number_end === numberParts[1];
                    };
                    return letterMatch() || numberEndMatch();
                  });
                  if (exactMatch.length !== 1) {
                    throw new Error('Too many address matches');
                  }
                }
                _this.selectPosition(position);
              } catch (_error) {
                err = _error;
                addressInfo = {
                  address: slug
                };
                Raven.captureException(err, {
                  extra: addressInfo
                });
              }
              return deferred.resolve({
                afterMapInit: function() {
                  if (level !== 'none') {
                    return _this._showAllUnits(level);
                  }
                }
              });
            });
          };
        })(this));
      };

      BaseControl.prototype._showAllUnits = function(level) {
        var bbox, bboxes, transformedBounds, _i, _len;
        transformedBounds = this.mapProxy.getTransformedBounds();
        bboxes = [];
        for (_i = 0, _len = transformedBounds.length; _i < _len; _i++) {
          bbox = transformedBounds[_i];
          bboxes.push("" + bbox[0][0] + "," + bbox[0][1] + "," + bbox[1][0] + "," + bbox[1][1]);
        }
        return this.addUnitsWithinBoundingBoxes(bboxes, level);
      };

      BaseControl.prototype.renderHome = function(path, context) {
        var defaultLevel, level;
        if (!((path == null) || path === '' || (path instanceof Array && (path.length = 0)))) {
          context = path;
        }
        level = this._getLevel(context, defaultLevel = 'none');
        this.reset();
        return sm.withDeferred((function(_this) {
          return function(d) {
            return d.resolve({
              afterMapInit: function() {
                if (level !== 'none') {
                  return _this._showAllUnits(level);
                }
              }
            });
          };
        })(this));
      };

      BaseControl.prototype.renderSearch = function(path, opts) {
        var _ref;
        if (((_ref = opts.query) != null ? _ref.q : void 0) == null) {
          return;
        }
        return this.search(opts.query.q);
      };

      BaseControl.prototype._matchResourceUrl = function(path) {
        var match;
        match = path.match(/^([0-9]+)/);
        if (match != null) {
          return match[0];
        }
      };

      BaseControl.prototype.renderUnit = function(path, opts) {
        var def, id, query;
        id = this._matchResourceUrl(path);
        if (id != null) {
          def = $.Deferred();
          this.renderUnitById(id).done((function(_this) {
            return function(unit) {
              return def.resolve({
                afterMapInit: function() {
                  return _this.selectUnit(unit);
                }
              });
            };
          })(this));
          return def.promise();
        }
        query = opts.query;
        if (query != null ? query.service : void 0) {
          return this.renderUnitsByServices(opts.query.service);
        }
      };

      return BaseControl;

    })(Marionette.Controller);
  });

}).call(this);

//# sourceMappingURL=control.js.map
