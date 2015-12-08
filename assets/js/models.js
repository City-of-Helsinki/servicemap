(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['moment', 'underscore', 'raven', 'backbone', 'i18next', 'cs!app/base', 'cs!app/settings', 'cs!app/spinner', 'cs!app/alphabet', 'cs!app/accessibility'], function(moment, _, Raven, Backbone, i18n, _arg, settings, SMSpinner, alphabet, accessibility) {
    var AddressList, AddressPosition, AdministrativeDivision, AdministrativeDivisionList, AdministrativeDivisionType, AdministrativeDivisionTypeList, BACKEND_BASE, CoordinatePosition, Department, DepartmentList, Event, EventList, FeedbackItem, FeedbackItemType, FeedbackList, FeedbackMessage, FilterableCollection, GeoModel, LINKEDEVENTS_BASE, Language, LanguageList, LinkedEventsCollection, LinkedEventsModel, MUNICIPALITIES, MUNICIPALITY_IDS, OPEN311_BASE, OPEN311_WRITE_BASE, Open311Model, Organization, OrganizationList, Position, PositionList, RESTFrameworkCollection, RoutingParameters, SMCollection, SMModel, SearchList, Service, ServiceList, Street, StreetList, Unit, UnitList, WrappedModel, exports, mixOf, pad, withDeferred;
    mixOf = _arg.mixOf, pad = _arg.pad, withDeferred = _arg.withDeferred;
    BACKEND_BASE = appSettings.service_map_backend;
    LINKEDEVENTS_BASE = appSettings.linkedevents_backend;
    OPEN311_BASE = appSettings.open311_backend;
    OPEN311_WRITE_BASE = appSettings.open311_write_backend + '/';
    MUNICIPALITIES = {
      49: 'espoo',
      91: 'helsinki',
      92: 'vantaa',
      235: 'kauniainen'
    };
    MUNICIPALITY_IDS = _.invert(MUNICIPALITIES);
    Backbone.ajax = function(request) {
      request = settings.applyAjaxDefaults(request);
      return Backbone.$.ajax.call(Backbone.$, request);
    };
    FilterableCollection = (function(_super) {
      __extends(FilterableCollection, _super);

      function FilterableCollection() {
        return FilterableCollection.__super__.constructor.apply(this, arguments);
      }

      FilterableCollection.prototype.initialize = function(options) {
        return this.filters = {};
      };

      FilterableCollection.prototype.setFilter = function(key, val) {
        if (!val) {
          if (key in this.filters) {
            delete this.filters[key];
          }
        } else {
          this.filters[key] = val;
        }
        return this;
      };

      FilterableCollection.prototype.clearFilters = function() {
        return this.filters = {};
      };

      FilterableCollection.prototype.fetch = function(options) {
        var data;
        data = _.clone(this.filters);
        if (options.data != null) {
          data = _.extend(data, options.data);
        }
        options.data = data;
        return FilterableCollection.__super__.fetch.call(this, options);
      };

      return FilterableCollection;

    })(Backbone.Collection);
    RESTFrameworkCollection = (function(_super) {
      __extends(RESTFrameworkCollection, _super);

      function RESTFrameworkCollection() {
        return RESTFrameworkCollection.__super__.constructor.apply(this, arguments);
      }

      RESTFrameworkCollection.prototype.parse = function(resp, options) {
        this.fetchState = {
          count: resp.count,
          next: resp.next,
          previous: resp.previous
        };
        return RESTFrameworkCollection.__super__.parse.call(this, resp.results, options);
      };

      return RESTFrameworkCollection;

    })(FilterableCollection);
    WrappedModel = (function(_super) {
      __extends(WrappedModel, _super);

      function WrappedModel() {
        return WrappedModel.__super__.constructor.apply(this, arguments);
      }

      WrappedModel.prototype.initialize = function(model) {
        WrappedModel.__super__.initialize.call(this);
        return this.wrap(model);
      };

      WrappedModel.prototype.wrap = function(model) {
        return this.set('value', model || null);
      };

      WrappedModel.prototype.value = function() {
        return this.get('value');
      };

      WrappedModel.prototype.isEmpty = function() {
        return !this.has('value');
      };

      WrappedModel.prototype.isSet = function() {
        return !this.isEmpty();
      };

      return WrappedModel;

    })(Backbone.Model);
    GeoModel = (function() {
      function GeoModel() {}

      GeoModel.prototype.getLatLng = function() {
        var coords, _ref;
        if (this.latLng != null) {
          this.latLng;
        }
        coords = (_ref = this.get('location')) != null ? _ref.coordinates : void 0;
        if (coords != null) {
          return this.latLng = L.GeoJSON.coordsToLatLng(coords);
        } else {
          return null;
        }
      };

      GeoModel.prototype.getDistanceToLastPosition = function() {
        var latLng, position;
        position = p13n.getLastPosition();
        if (position != null) {
          latLng = this.getLatLng();
          if (latLng != null) {
            return position.getLatLng().distanceTo(latLng);
          } else {
            return Number.MAX_VALUE;
          }
        }
      };

      return GeoModel;

    })();
    SMModel = (function(_super) {
      __extends(SMModel, _super);

      function SMModel() {
        return SMModel.__super__.constructor.apply(this, arguments);
      }

      SMModel.prototype.getText = function(attr) {
        var val;
        val = this.get(attr);
        if (__indexOf.call(this.translatedAttrs, attr) >= 0) {
          return p13n.getTranslatedAttr(val);
        }
        return val;
      };

      SMModel.prototype.toJSON = function(options) {
        var attr, data, _i, _len, _ref;
        data = SMModel.__super__.toJSON.call(this);
        if (!this.translatedAttrs) {
          return data;
        }
        _ref = this.translatedAttrs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          if (!(attr in data)) {
            continue;
          }
          data[attr] = p13n.getTranslatedAttr(data[attr]);
        }
        return data;
      };

      SMModel.prototype.url = function() {
        var ret;
        ret = SMModel.__super__.url.apply(this, arguments);
        if (ret.substr(-1 !== '/')) {
          ret = ret + '/';
        }
        return ret;
      };

      SMModel.prototype.urlRoot = function() {
        return "" + BACKEND_BASE + "/" + this.resourceName + "/";
      };

      return SMModel;

    })(Backbone.Model);
    SMCollection = (function(_super) {
      __extends(SMCollection, _super);

      function SMCollection() {
        this.comparatorWrapper = __bind(this.comparatorWrapper, this);
        this.getComparator = __bind(this.getComparator, this);
        return SMCollection.__super__.constructor.apply(this, arguments);
      }

      SMCollection.prototype.initialize = function(models, options) {
        this.filters = {};
        this.currentPage = 1;
        if (options != null) {
          this.pageSize = options.pageSize || 25;
          if (options.setComparator) {
            this.setDefaultComparator();
          }
        }
        return SMCollection.__super__.initialize.call(this, options);
      };

      SMCollection.prototype.url = function() {
        var obj;
        obj = new this.model;
        return "" + BACKEND_BASE + "/" + obj.resourceName + "/";
      };

      SMCollection.prototype.isSet = function() {
        return !this.isEmpty();
      };

      SMCollection.prototype.setFilter = function(key, val) {
        if (!val) {
          if (key in this.filters) {
            delete this.filters[key];
          }
        } else {
          this.filters[key] = val;
        }
        return this;
      };

      SMCollection.prototype.clearFilters = function() {
        return this.filters = {};
      };

      SMCollection.prototype.fetchNext = function(options) {
        var defaults;
        if ((this.fetchState != null) && !this.fetchState.next) {
          return false;
        }
        this.currentPage++;
        defaults = {
          reset: false,
          remove: false
        };
        if (options != null) {
          options = _.extend(options, defaults);
        } else {
          options = defaults;
        }
        return this.fetch(options);
      };

      SMCollection.prototype.fetch = function(options) {
        var error, spinner, success, _ref;
        if (options != null) {
          options = _.clone(options);
        } else {
          options = {};
        }
        if (options.data == null) {
          options.data = {};
        }
        options.data.page = this.currentPage;
        options.data.page_size = this.pageSize;
        if ((_ref = options.spinnerOptions) != null ? _ref.container : void 0) {
          spinner = new SMSpinner(options.spinnerOptions);
          spinner.start();
          success = options.success;
          error = options.error;
          options.success = function(collection, response, options) {
            spinner.stop();
            return typeof success === "function" ? success(collection, response, options) : void 0;
          };
          options.error = function(collection, response, options) {
            spinner.stop();
            return typeof error === "function" ? error(collection, response, options) : void 0;
          };
        }
        delete options.spinnerOptions;
        return SMCollection.__super__.fetch.call(this, options);
      };

      SMCollection.prototype.fetchFields = function(start, end, fields) {
        var filtered, idsToFetch;
        if (!fields) {
          return $.Deferred().resolve().promise();
        }
        filtered = _(this.slice(start, end)).filter((function(_this) {
          return function(m) {
            var field, _i, _len;
            for (_i = 0, _len = fields.length; _i < _len; _i++) {
              field = fields[_i];
              if (m.get(field) === void 0) {
                return true;
              }
            }
            return false;
          };
        })(this));
        idsToFetch = _.pluck(filtered, 'id');
        if (!idsToFetch.length) {
          return $.Deferred().resolve().promise();
        }
        return this.fetch({
          remove: false,
          data: {
            page_size: idsToFetch.length,
            id: idsToFetch.join(','),
            include: fields.join(',')
          }
        });
      };

      SMCollection.prototype.getComparatorKeys = function() {
        return ['default', 'alphabetic', 'alphabetic_reverse'];
      };

      SMCollection.prototype.getComparator = function(key, direction) {
        switch (key) {
          case 'alphabetic':
            return alphabet.makeComparator(direction);
          case 'alphabetic_reverse':
            return alphabet.makeComparator(-1);
          case 'distance':
            return (function(_this) {
              return function(x) {
                return x.getDistanceToLastPosition();
              };
            })(this);
          case 'distance_precalculated':
            return (function(_this) {
              return function(x) {
                return x.get('distance');
              };
            })(this);
          case 'default':
            return (function(_this) {
              return function(x) {
                return -x.get('score');
              };
            })(this);
          case 'accessibility':
            return (function(_this) {
              return function(x) {
                return x.getShortcomingCount();
              };
            })(this);
          default:
            return null;
        }
      };

      SMCollection.prototype.comparatorWrapper = function(fn) {
        if (!fn) {
          return fn;
        }
        if (fn.length === 2) {
          return (function(_this) {
            return function(a, b) {
              return fn(a.getComparisonKey(), b.getComparisonKey());
            };
          })(this);
        } else {
          return fn;
        }
      };

      SMCollection.prototype.setDefaultComparator = function() {
        return this.setComparator(this.getComparatorKeys()[0]);
      };

      SMCollection.prototype.setComparator = function(key, direction) {
        var index;
        index = this.getComparatorKeys().indexOf(key);
        if (index !== -1) {
          this.currentComparator = index;
          this.currentComparatorKey = key;
          return this.comparator = this.comparatorWrapper(this.getComparator(key, direction));
        }
      };

      SMCollection.prototype.cycleComparator = function() {
        if (this.currentComparator == null) {
          this.currentComparator = 0;
        }
        this.currentComparator += 1;
        this.currentComparator %= this.getComparatorKeys().length;
        return this.reSort(this.getComparatorKeys()[this.currentComparator]);
      };

      SMCollection.prototype.reSort = function(key, direction) {
        this.setComparator(key, direction);
        if (this.comparator != null) {
          this.sort();
        }
        return key;
      };

      SMCollection.prototype.getComparatorKey = function() {
        return this.currentComparatorKey;
      };

      SMCollection.prototype.hasReducedPriority = function() {
        return false;
      };

      return SMCollection;

    })(RESTFrameworkCollection);
    Unit = (function(_super) {
      __extends(Unit, _super);

      function Unit() {
        return Unit.__super__.constructor.apply(this, arguments);
      }

      Unit.prototype.resourceName = 'unit';

      Unit.prototype.translatedAttrs = ['name', 'description', 'street_address'];

      Unit.prototype.initialize = function(options) {
        Unit.__super__.initialize.call(this, options);
        this.eventList = new EventList();
        return this.feedbackList = new FeedbackList();
      };

      Unit.prototype.getEvents = function(filters, options) {
        if (filters == null) {
          filters = {};
        }
        if (!('start' in filters)) {
          filters.start = 'today';
        }
        if (!('sort' in filters)) {
          filters.sort = 'start_time';
        }
        filters.location = "tprek:" + (this.get('id'));
        this.eventList.filters = filters;
        if (options == null) {
          options = {
            reset: true
          };
        } else if (!options.reset) {
          options.reset = true;
        }
        return this.eventList.fetch(options);
      };

      Unit.prototype.getFeedback = function(options) {
        this.feedbackList.setFilter('service_object_id', this.id);
        options = options || {};
        _.extend(options, {
          reset: true
        });
        return this.feedbackList.fetch(options);
      };

      Unit.prototype.isDetectedLocation = function() {
        return false;
      };

      Unit.prototype.isPending = function() {
        return false;
      };

      Unit.prototype.otpSerializeLocation = function(opts) {
        var coords;
        if (opts.forceCoordinates) {
          coords = this.get('location').coordinates;
          return "" + coords[1] + "," + coords[0];
        } else {
          return "poi:tprek:" + (this.get('id'));
        }
      };

      Unit.prototype.getSpecifierText = function() {
        var level, service, specifierText, _i, _len, _ref;
        specifierText = '';
        if (this.get('services') == null) {
          return specifierText;
        }
        level = null;
        _ref = this.get('services');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          service = _ref[_i];
          if (!level || service.level < level) {
            specifierText = service.name[p13n.getLanguage()];
            level = service.level;
          }
        }
        return specifierText;
      };

      Unit.prototype.getComparisonKey = function() {
        return p13n.getTranslatedAttr(this.get('name'));
      };

      Unit.prototype.toJSON = function(options) {
        var data, highlights, lang, links, openingHours;
        data = Unit.__super__.toJSON.call(this);
        openingHours = _.filter(this.get('connections'), function(c) {
          return c.section === 'opening_hours' && p13n.getLanguage() in c.name;
        });
        lang = p13n.getLanguage();
        if (openingHours.length > 0) {
          data.opening_hours = _(openingHours).chain().sortBy('type').map((function(_this) {
            return function(hours) {
              var _ref;
              return {
                content: hours.name[lang],
                url: (_ref = hours.www_url) != null ? _ref[lang] : void 0
              };
            };
          })(this)).value();
        }
        highlights = _.filter(this.get('connections'), function(c) {
          return c.section === 'miscellaneous' && p13n.getLanguage() in c.name;
        });
        data.highlights = _.sortBy(highlights, function(c) {
          return c.type;
        });
        links = _.filter(this.get('connections'), function(c) {
          return c.section === 'links' && p13n.getLanguage() in c.name;
        });
        data.links = _.sortBy(links, function(c) {
          return c.type;
        });
        return data;
      };

      Unit.prototype.hasBboxFilter = function() {
        var _ref, _ref1;
        return ((_ref = this.collection) != null ? (_ref1 = _ref.filters) != null ? _ref1.bbox : void 0 : void 0) != null;
      };

      Unit.prototype.hasAccessibilityData = function() {
        var blacklistHits, fn, _ref;
        fn = function(x) {
          var _ref;
          return (_ref = x.id) === 33467 || _ref === 33399;
        };
        blacklistHits = _(this.get('services')).filter(fn).length;
        return ((_ref = this.get('accessibility_properties')) != null ? _ref.length : void 0) && blacklistHits === 0;
      };

      Unit.prototype.getTranslatedShortcomings = function() {
        var profiles, shortcomings, status, _ref;
        profiles = p13n.getAccessibilityProfileIds();
        return _ref = accessibility.getTranslatedShortcomings(profiles, this), status = _ref.status, shortcomings = _ref.results, _ref;
      };

      Unit.prototype.getShortcomingCount = function() {
        var group, shortcomings, __, _ref;
        if (!this.hasAccessibilityData()) {
          return Number.MAX_VALUE;
        }
        shortcomings = this.getTranslatedShortcomings();
        this.shortcomingCount = 0;
        _ref = shortcomings.results;
        for (__ in _ref) {
          group = _ref[__];
          this.shortcomingCount += _.values(group).length;
        }
        return this.shortcomingCount;
      };

      return Unit;

    })(mixOf(SMModel, GeoModel));
    UnitList = (function(_super) {
      __extends(UnitList, _super);

      function UnitList() {
        return UnitList.__super__.constructor.apply(this, arguments);
      }

      UnitList.prototype.model = Unit;

      UnitList.prototype.comparator = null;

      UnitList.prototype.initialize = function(models, opts) {
        UnitList.__super__.initialize.call(this, models, opts);
        return this.forcedPriority = opts != null ? opts.forcedPriority : void 0;
      };

      UnitList.prototype.getComparatorKeys = function() {
        var keys;
        keys = [];
        if (p13n.hasAccessibilityIssues()) {
          keys.push('accessibility');
        }
        if (this.overrideComparatorKeys != null) {
          return _(this.overrideComparatorKeys).union(keys);
        }
        return _(keys).union(['default', 'distance', 'alphabetic', 'alphabetic_reverse']);
      };

      UnitList.prototype.hasReducedPriority = function() {
        var ret, _ref;
        ret = this.forcedPriority ? false : ((_ref = this.filters) != null ? _ref.bbox : void 0) != null;
        return ret;
      };

      return UnitList;

    })(SMCollection);
    Department = (function(_super) {
      __extends(Department, _super);

      function Department() {
        return Department.__super__.constructor.apply(this, arguments);
      }

      Department.prototype.resourceName = 'department';

      Department.prototype.translatedAttrs = ['name'];

      return Department;

    })(SMModel);
    DepartmentList = (function(_super) {
      __extends(DepartmentList, _super);

      function DepartmentList() {
        return DepartmentList.__super__.constructor.apply(this, arguments);
      }

      DepartmentList.prototype.model = Department;

      return DepartmentList;

    })(SMCollection);
    Organization = (function(_super) {
      __extends(Organization, _super);

      function Organization() {
        return Organization.__super__.constructor.apply(this, arguments);
      }

      Organization.prototype.resourceName = 'organization';

      Organization.prototype.translatedAttrs = ['name'];

      return Organization;

    })(SMModel);
    OrganizationList = (function(_super) {
      __extends(OrganizationList, _super);

      function OrganizationList() {
        return OrganizationList.__super__.constructor.apply(this, arguments);
      }

      OrganizationList.prototype.model = Organization;

      return OrganizationList;

    })(SMCollection);
    AdministrativeDivision = (function(_super) {
      __extends(AdministrativeDivision, _super);

      function AdministrativeDivision() {
        return AdministrativeDivision.__super__.constructor.apply(this, arguments);
      }

      AdministrativeDivision.prototype.resourceName = 'administrative_division';

      AdministrativeDivision.prototype.translatedAttrs = ['name'];

      AdministrativeDivision.prototype.getEmergencyCareUnit = function() {
        if (this.get('type') === 'emergency_care_district') {
          switch (this.get('ocd_id')) {
            case 'ocd-division/country:fi/kunta:helsinki/päivystysalue:haartmanin_päivystysalue':
              return 11828;
            case 'ocd-division/country:fi/kunta:helsinki/päivystysalue:marian_päivystysalue':
              return 4060;
            case 'ocd-division/country:fi/kunta:helsinki/päivystysalue:malmin_päivystysalue':
              return 4060;
          }
        }
        return null;
      };

      return AdministrativeDivision;

    })(SMModel);
    AdministrativeDivisionList = (function(_super) {
      __extends(AdministrativeDivisionList, _super);

      function AdministrativeDivisionList() {
        return AdministrativeDivisionList.__super__.constructor.apply(this, arguments);
      }

      AdministrativeDivisionList.prototype.model = AdministrativeDivision;

      return AdministrativeDivisionList;

    })(SMCollection);
    AdministrativeDivisionType = (function(_super) {
      __extends(AdministrativeDivisionType, _super);

      function AdministrativeDivisionType() {
        return AdministrativeDivisionType.__super__.constructor.apply(this, arguments);
      }

      AdministrativeDivisionType.prototype.resourceName = 'administrative_division_type';

      return AdministrativeDivisionType;

    })(SMModel);
    AdministrativeDivisionTypeList = (function(_super) {
      __extends(AdministrativeDivisionTypeList, _super);

      function AdministrativeDivisionTypeList() {
        return AdministrativeDivisionTypeList.__super__.constructor.apply(this, arguments);
      }

      AdministrativeDivisionTypeList.prototype.model = AdministrativeDivision;

      return AdministrativeDivisionTypeList;

    })(SMCollection);
    Service = (function(_super) {
      __extends(Service, _super);

      function Service() {
        return Service.__super__.constructor.apply(this, arguments);
      }

      Service.prototype.resourceName = 'service';

      Service.prototype.translatedAttrs = ['name'];

      Service.prototype.initialize = function() {
        var units;
        this.set('units', new models.UnitList(null, {
          setComparator: true
        }));
        units = this.get('units');
        units.overrideComparatorKeys = ['alphabetic', 'alphabetic_reverse', 'distance'];
        return units.setDefaultComparator();
      };

      Service.prototype.getSpecifierText = function() {
        var ancestor, index, specifierText, _i, _len, _ref;
        specifierText = '';
        if (this.get('ancestors') == null) {
          return specifierText;
        }
        _ref = this.get('ancestors');
        for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
          ancestor = _ref[index];
          if (index > 0) {
            specifierText += ' • ';
          }
          specifierText += ancestor.name[p13n.getLanguage()];
        }
        return specifierText;
      };

      Service.prototype.getComparisonKey = function() {
        return p13n.getTranslatedAttr(this.get('name'));
      };

      return Service;

    })(SMModel);
    Street = (function(_super) {
      __extends(Street, _super);

      function Street() {
        return Street.__super__.constructor.apply(this, arguments);
      }

      Street.prototype.resourceName = 'street';

      Street.prototype.humanAddress = function() {
        var name;
        name = p13n.getTranslatedAttr(this.get('name'));
        return "" + name + ", " + (this.getMunicipalityName());
      };

      Street.prototype.getMunicipalityName = function() {
        return i18n.t("municipality." + (this.get('municipality')));
      };

      return Street;

    })(SMModel);
    StreetList = (function(_super) {
      __extends(StreetList, _super);

      function StreetList() {
        return StreetList.__super__.constructor.apply(this, arguments);
      }

      StreetList.prototype.model = Street;

      return StreetList;

    })(SMCollection);
    Position = (function(_super) {
      __extends(Position, _super);

      function Position() {
        return Position.__super__.constructor.apply(this, arguments);
      }

      Position.prototype.resourceName = 'address';

      Position.prototype.origin = function() {
        return 'clicked';
      };

      Position.prototype.isPending = function() {
        return false;
      };

      Position.prototype.urlRoot = function() {
        return "" + BACKEND_BASE + "/" + this.resourceName;
      };

      Position.prototype.parse = function(response, options) {
        var data, street;
        data = Position.__super__.parse.call(this, response, options);
        street = data.street;
        if (street) {
          data.street = new Street(street);
        }
        return data;
      };

      Position.prototype.isDetectedLocation = function() {
        return false;
      };

      Position.prototype.isReverseGeocoded = function() {
        return this.get('street') != null;
      };

      Position.prototype.getSpecifierText = function() {
        return this.getMunicipalityName();
      };

      Position.prototype.slugifyAddress = function() {
        var SEPARATOR, add, letter, municipality, numberEnd, slug, street;
        SEPARATOR = '-';
        municipality = this.get('street').get('municipality');
        slug = [];
        add = function(x) {
          return slug.push(x);
        };
        street = this.get('street').get('name').fi.toLowerCase().replace(/\ /g, SEPARATOR);
        add(this.get('number'));
        numberEnd = this.get('number_end');
        letter = this.get('letter');
        if (numberEnd) {
          add("" + SEPARATOR + numberEnd);
        }
        if (letter) {
          slug[slug.length - 1] += SEPARATOR + letter;
        }
        this.slug = "" + municipality + "/" + street + "/" + (slug.join(SEPARATOR));
        return this.slug;
      };

      Position.prototype.humanAddress = function(opts) {
        var last, result, street, _ref;
        street = this.get('street');
        result = [];
        if (street != null) {
          result.push(p13n.getTranslatedAttr(street.get('name')));
          result.push(this.humanNumber());
          if (!(opts != null ? (_ref = opts.exclude) != null ? _ref.municipality : void 0 : void 0) && street.get('municipality')) {
            last = result.pop();
            last += ',';
            result.push(last);
            result.push(this.getMunicipalityName());
          }
          return result.join(' ');
        } else {
          return null;
        }
      };

      Position.prototype.getMunicipalityName = function() {
        return this.get('street').getMunicipalityName();
      };

      Position.prototype.getComparisonKey = function(model) {
        var letter, number, result, street, _ref;
        street = this.get('street');
        result = [];
        if (street != null) {
          result.push(i18n.t("municipality." + (street.get('municipality'))));
          _ref = [this.get('number'), this.get('letter')], number = _ref[0], letter = _ref[1];
          result.push(pad(number));
          result.push(letter);
        }
        return result.join('');
      };

      Position.prototype._humanNumber = function() {
        var result;
        result = [];
        if (this.get('number')) {
          result.push(this.get('number'));
        }
        if (this.get('number_end')) {
          result.push('-');
          result.push(this.get('number_end'));
        }
        if (this.get('letter')) {
          result.push(this.get('letter'));
        }
        return result;
      };

      Position.prototype.humanNumber = function() {
        return this._humanNumber().join('');
      };

      Position.prototype.otpSerializeLocation = function(opts) {
        var coords;
        coords = this.get('location').coordinates;
        return "" + coords[1] + "," + coords[0];
      };

      return Position;

    })(mixOf(SMModel, GeoModel));
    AddressList = (function(_super) {
      __extends(AddressList, _super);

      function AddressList() {
        return AddressList.__super__.constructor.apply(this, arguments);
      }

      AddressList.prototype.model = Position;

      return AddressList;

    })(SMCollection);
    CoordinatePosition = (function(_super) {
      __extends(CoordinatePosition, _super);

      function CoordinatePosition() {
        return CoordinatePosition.__super__.constructor.apply(this, arguments);
      }

      CoordinatePosition.prototype.origin = function() {
        if (this.isDetectedLocation()) {
          return 'detected';
        } else {
          return CoordinatePosition.__super__.origin.call(this);
        }
      };

      CoordinatePosition.prototype.initialize = function(attrs) {
        return this.isDetected = (attrs != null ? attrs.isDetected : void 0) != null ? attrs.isDetected : false;
      };

      CoordinatePosition.prototype.isDetectedLocation = function() {
        return this.isDetected;
      };

      CoordinatePosition.prototype.reverseGeocode = function() {
        return withDeferred((function(_this) {
          return function(deferred) {
            var posList;
            if (_this.get('street') == null) {
              posList = models.PositionList.fromPosition(_this);
              return _this.listenTo(posList, 'sync', function() {
                var bestMatch;
                bestMatch = posList.first();
                if (bestMatch.get('distance') > 500) {
                  bestMatch.set('name', i18n.t('map.unknown_address'));
                }
                _this.set(bestMatch.toJSON());
                deferred.resolve();
                return _this.trigger('reverse-geocode');
              });
            }
          };
        })(this));
      };

      CoordinatePosition.prototype.isPending = function() {
        return this.get('location') == null;
      };

      return CoordinatePosition;

    })(Position);
    AddressPosition = (function(_super) {
      __extends(AddressPosition, _super);

      function AddressPosition() {
        return AddressPosition.__super__.constructor.apply(this, arguments);
      }

      AddressPosition.prototype.origin = function() {
        return 'address';
      };

      AddressPosition.prototype.initialize = function(data) {
        if (data == null) {
          return;
        }
        AddressPosition.__super__.initialize.apply(this, arguments);
        return this.set('location', {
          coordinates: data.location.coordinates,
          type: 'Point'
        });
      };

      AddressPosition.prototype.isDetectedLocation = function() {
        return false;
      };

      return AddressPosition;

    })(Position);
    PositionList = (function(_super) {
      __extends(PositionList, _super);

      function PositionList() {
        return PositionList.__super__.constructor.apply(this, arguments);
      }

      PositionList.prototype.resourceName = 'address';

      PositionList.fromPosition = function(position) {
        var instance, location, name, opts, _ref;
        instance = new PositionList();
        name = (_ref = position.get('street')) != null ? _ref.get('name') : void 0;
        location = position.get('location');
        instance.model = Position;
        if (location && !name) {
          instance.fetch({
            data: {
              lat: location.coordinates[1],
              lon: location.coordinates[0]
            }
          });
        } else if (name && !location) {
          opts = {
            data: {
              municipality: position.get('street').get('municipality'),
              number: position.get('number'),
              street: name
            }
          };
          instance.fetch(opts);
        }
        return instance;
      };

      PositionList.fromSlug = function(municipality, streetName, numberPart) {
        var SEPARATOR, number, numberParts, street;
        SEPARATOR = /-/g;
        numberParts = numberPart.split(SEPARATOR);
        number = numberParts[0];
        number = numberPart.replace(/-.*$/, '');
        street = new Street({
          name: streetName.replace(SEPARATOR, ' '),
          municipality: municipality
        });
        return this.fromPosition(new Position({
          street: street,
          number: number
        }));
      };

      PositionList.prototype.getComparatorKeys = function() {
        return ['alphabetic'];
      };

      PositionList.prototype.url = function() {
        return "" + BACKEND_BASE + "/" + this.resourceName + "/";
      };

      return PositionList;

    })(SMCollection);
    RoutingParameters = (function(_super) {
      __extends(RoutingParameters, _super);

      function RoutingParameters() {
        return RoutingParameters.__super__.constructor.apply(this, arguments);
      }

      RoutingParameters.prototype.initialize = function(attributes) {
        this.set('endpoints', (attributes != null ? attributes.endpoints.slice(0) : void 0) || [null, null]);
        this.set('origin_index', (attributes != null ? attributes.origin_index : void 0) || 0);
        this.set('time_mode', (attributes != null ? attributes.time_mode : void 0) || 'depart');
        this.pendingPosition = new CoordinatePosition({
          isDetected: false,
          preventPopup: true
        });
        return this.listenTo(this, 'change:time_mode', function() {
          return this.triggerComplete();
        });
      };

      RoutingParameters.prototype.swapEndpoints = function(opts) {
        this.set('origin_index', this._getDestinationIndex());
        if (!(opts != null ? opts.silent : void 0)) {
          this.trigger('change');
          return this.triggerComplete();
        }
      };

      RoutingParameters.prototype.setOrigin = function(object, opts) {
        var index;
        index = this.get('origin_index');
        this.get('endpoints')[index] = object;
        this.trigger('change');
        if (!(opts != null ? opts.silent : void 0)) {
          return this.triggerComplete();
        }
      };

      RoutingParameters.prototype.setDestination = function(object) {
        this.get('endpoints')[this._getDestinationIndex()] = object;
        this.trigger('change');
        return this.triggerComplete();
      };

      RoutingParameters.prototype.getDestination = function() {
        return this.get('endpoints')[this._getDestinationIndex()];
      };

      RoutingParameters.prototype.getOrigin = function() {
        return this.get('endpoints')[this._getOriginIndex()];
      };

      RoutingParameters.prototype.getEndpointName = function(object) {
        if (object == null) {
          return '';
        } else if (object.isDetectedLocation()) {
          if (object.isPending()) {
            return i18n.t('transit.location_pending');
          } else {
            return i18n.t('transit.current_location');
          }
        } else if (object instanceof CoordinatePosition) {
          return i18n.t('transit.user_picked_location');
        } else if (object instanceof Unit) {
          return object.getText('name');
        } else if (object instanceof Position) {
          return object.humanAddress();
        }
      };

      RoutingParameters.prototype.getEndpointLocking = function(object) {
        return object instanceof models.Unit;
      };

      RoutingParameters.prototype.isComplete = function() {
        var endpoint, _i, _len, _ref;
        _ref = this.get('endpoints');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          endpoint = _ref[_i];
          if (endpoint == null) {
            return false;
          }
          if (endpoint instanceof Position) {
            if (endpoint.isPending()) {
              return false;
            }
          }
        }
        return true;
      };

      RoutingParameters.prototype.ensureUnitDestination = function() {
        if (this.getOrigin() instanceof Unit) {
          return this.swapEndpoints({
            silent: true
          });
        }
      };

      RoutingParameters.prototype.triggerComplete = function() {
        if (this.isComplete()) {
          return this.trigger('complete');
        }
      };

      RoutingParameters.prototype.setTime = function(time, opts) {
        var datetime, m, mt;
        datetime = this.getDatetime();
        mt = moment(time);
        m = moment(datetime);
        m.hours(mt.hours());
        m.minutes(mt.minutes());
        datetime = m.toDate();
        this.set('time', datetime, opts);
        return this.triggerComplete();
      };

      RoutingParameters.prototype.setDate = function(date, opts) {
        var datetime, md;
        datetime = this.getDatetime();
        md = moment(date);
        datetime.setDate(md.date());
        datetime.setMonth(md.month());
        datetime.setYear(md.year());
        this.set('time', datetime, opts);
        return this.triggerComplete();
      };

      RoutingParameters.prototype.setTimeAndDate = function(date) {
        this.setTime(date);
        return this.setDate(date);
      };

      RoutingParameters.prototype.setDefaultDatetime = function() {
        this.set('time', this.getDefaultDatetime());
        return this.triggerComplete();
      };

      RoutingParameters.prototype.clearTime = function() {
        return this.set('time', null);
      };

      RoutingParameters.prototype.getDefaultDatetime = function(currentDatetime) {
        var minutes, mode, time;
        time = moment(new Date());
        mode = this.get('time_mode');
        if (mode === 'depart') {
          return time.toDate();
        }
        time.add(60, 'minutes');
        minutes = time.minutes();
        time.minutes(minutes - minutes % 10 + 10);
        return time.toDate();
      };

      RoutingParameters.prototype.getDatetime = function() {
        var time;
        time = this.get('time');
        if (time == null) {
          time = this.getDefaultDatetime();
        }
        return time;
      };

      RoutingParameters.prototype.isTimeSet = function() {
        return this.get('time') != null;
      };

      RoutingParameters.prototype.setTimeMode = function(timeMode) {
        this.set('time_mode', timeMode);
        return this.triggerComplete();
      };

      RoutingParameters.prototype._getOriginIndex = function() {
        return this.get('origin_index');
      };

      RoutingParameters.prototype._getDestinationIndex = function() {
        return (this._getOriginIndex() + 1) % 2;
      };

      return RoutingParameters;

    })(Backbone.Model);
    Language = (function(_super) {
      __extends(Language, _super);

      function Language() {
        return Language.__super__.constructor.apply(this, arguments);
      }

      return Language;

    })(Backbone.Model);
    LanguageList = (function(_super) {
      __extends(LanguageList, _super);

      function LanguageList() {
        return LanguageList.__super__.constructor.apply(this, arguments);
      }

      LanguageList.prototype.model = Language;

      return LanguageList;

    })(Backbone.Collection);
    ServiceList = (function(_super) {
      __extends(ServiceList, _super);

      function ServiceList() {
        return ServiceList.__super__.constructor.apply(this, arguments);
      }

      ServiceList.prototype.model = Service;

      ServiceList.prototype.initialize = function() {
        ServiceList.__super__.initialize.apply(this, arguments);
        return this.chosenService = null;
      };

      ServiceList.prototype.expand = function(id, spinnerOptions) {
        if (spinnerOptions == null) {
          spinnerOptions = {};
        }
        if (!id) {
          this.chosenService = null;
          return this.fetch({
            data: {
              level: 0
            },
            spinnerOptions: spinnerOptions,
            success: (function(_this) {
              return function() {
                return _this.trigger('finished');
              };
            })(this)
          });
        } else {
          this.chosenService = new Service({
            id: id
          });
          return this.chosenService.fetch({
            success: (function(_this) {
              return function() {
                return _this.fetch({
                  data: {
                    parent: id
                  },
                  spinnerOptions: spinnerOptions,
                  success: function() {
                    return _this.trigger('finished');
                  }
                });
              };
            })(this)
          });
        }
      };

      return ServiceList;

    })(SMCollection);
    SearchList = (function(_super) {
      __extends(SearchList, _super);

      function SearchList() {
        return SearchList.__super__.constructor.apply(this, arguments);
      }

      SearchList.prototype.model = function(attrs, options) {
        var type, typeToModel;
        typeToModel = {
          service: Service,
          unit: Unit,
          address: Position
        };
        type = attrs.object_type;
        if (type in typeToModel) {
          return new typeToModel[type](attrs, options);
        } else {
          Raven.captureException(new Error("Unknown search result type '" + type + "', " + attrs.object_type));
          return new Backbone.Model(attrs, options);
        }
      };

      SearchList.prototype.search = function(query, options) {
        var city, opts;
        this.currentPage = 1;
        this.query = query;
        opts = _.extend({}, options);
        opts.data = {
          q: query,
          language: p13n.getLanguage(),
          only: 'unit.name,service.name,unit.location,unit.root_services',
          include: 'unit.accessibility_properties,service.ancestors,unit.services'
        };
        city = p13n.get('city');
        if (city) {
          opts.data.municipality = city;
        }
        this.fetch(opts);
        return opts;
      };

      SearchList.prototype.url = function() {
        return "" + BACKEND_BASE + "/search/";
      };

      return SearchList;

    })(SMCollection);
    LinkedEventsModel = (function(_super) {
      __extends(LinkedEventsModel, _super);

      function LinkedEventsModel() {
        return LinkedEventsModel.__super__.constructor.apply(this, arguments);
      }

      LinkedEventsModel.prototype.urlRoot = function() {
        return "" + LINKEDEVENTS_BASE + "/" + this.resourceName + "/";
      };

      return LinkedEventsModel;

    })(SMModel);
    LinkedEventsCollection = (function(_super) {
      __extends(LinkedEventsCollection, _super);

      function LinkedEventsCollection() {
        return LinkedEventsCollection.__super__.constructor.apply(this, arguments);
      }

      LinkedEventsCollection.prototype.url = function() {
        var obj;
        obj = new this.model;
        return "" + LINKEDEVENTS_BASE + "/" + obj.resourceName + "/";
      };

      LinkedEventsCollection.prototype.parse = function(resp, options) {
        this.fetchState = {
          count: resp.meta.count,
          next: resp.meta.next,
          previous: resp.meta.previous
        };
        return RESTFrameworkCollection.__super__.parse.call(this, resp.data, options);
      };

      return LinkedEventsCollection;

    })(SMCollection);
    Event = (function(_super) {
      __extends(Event, _super);

      function Event() {
        return Event.__super__.constructor.apply(this, arguments);
      }

      Event.prototype.resourceName = 'event';

      Event.prototype.translatedAttrs = ['name', 'info_url', 'description', 'short_description', 'location_extra_info'];

      Event.prototype.toJSON = function(options) {
        var data;
        data = Event.__super__.toJSON.call(this);
        data.links = _.filter(this.get('external_links'), function(link) {
          return link.language === p13n.getLanguage();
        });
        return data;
      };

      Event.prototype.getUnit = function() {
        var unitId;
        unitId = this.get('location')['@id'].match(/^.*tprek%3A(\d+)/);
        if (unitId == null) {
          return null;
        }
        return new models.Unit({
          id: unitId[1]
        });
      };

      return Event;

    })(LinkedEventsModel);
    EventList = (function(_super) {
      __extends(EventList, _super);

      function EventList() {
        return EventList.__super__.constructor.apply(this, arguments);
      }

      EventList.prototype.model = Event;

      return EventList;

    })(LinkedEventsCollection);
    Open311Model = (function(_super) {
      __extends(Open311Model, _super);

      function Open311Model() {
        return Open311Model.__super__.constructor.apply(this, arguments);
      }

      Open311Model.prototype.sync = function(method, model, options) {
        _.defaults(options, {
          emulateJSON: true,
          data: {
            extensions: true
          }
        });
        return Open311Model.__super__.sync.call(this, method, model, options);
      };

      Open311Model.prototype.resourceNamePlural = function() {
        return "" + this.resourceName + "s";
      };

      Open311Model.prototype.urlRoot = function() {
        return "" + OPEN311_BASE + "/" + (this.resourceNamePlural());
      };

      return Open311Model;

    })(SMModel);
    FeedbackItem = (function(_super) {
      __extends(FeedbackItem, _super);

      function FeedbackItem() {
        return FeedbackItem.__super__.constructor.apply(this, arguments);
      }

      FeedbackItem.prototype.resourceName = 'request';

      FeedbackItem.prototype.url = function() {
        return "" + (this.urlRoot()) + "/" + this.id + ".json";
      };

      FeedbackItem.prototype.parse = function(resp, options) {
        if (resp.length === 1) {
          return FeedbackItem.__super__.parse.call(this, resp[0], options);
        }
        return FeedbackItem.__super__.parse.call(this, resp, options);
      };

      return FeedbackItem;

    })(Open311Model);
    FeedbackItemType = (function(_super) {
      __extends(FeedbackItemType, _super);

      function FeedbackItemType() {
        return FeedbackItemType.__super__.constructor.apply(this, arguments);
      }

      return FeedbackItemType;

    })(Open311Model);
    FeedbackList = (function(_super) {
      __extends(FeedbackList, _super);

      function FeedbackList() {
        return FeedbackList.__super__.constructor.apply(this, arguments);
      }

      FeedbackList.prototype.fetch = function(options) {
        options = options || {};
        _.defaults(options, {
          emulateJSON: true,
          data: {
            extensions: true
          }
        });
        return FeedbackList.__super__.fetch.call(this, options);
      };

      FeedbackList.prototype.model = FeedbackItem;

      FeedbackList.prototype.url = function() {
        var obj;
        obj = new this.model;
        return "" + OPEN311_BASE + "/" + (obj.resourceNamePlural()) + ".json";
      };

      return FeedbackList;

    })(FilterableCollection);
    FeedbackMessage = (function(_super) {
      __extends(FeedbackMessage, _super);

      function FeedbackMessage() {
        return FeedbackMessage.__super__.constructor.apply(this, arguments);
      }

      FeedbackMessage.prototype.initialize = function() {
        this.set('can_be_published', true);
        this.set('service_request_type', 'OTHER');
        return this.set('description', '');
      };

      FeedbackMessage.prototype._serviceCodeFromPersonalisation = function(type) {
        switch (type) {
          case 'hearing_aid':
            return 128;
          case 'visually_impaired':
            return 126;
          case 'wheelchair':
            return 121;
          case 'reduced_mobility':
            return 123;
          case 'rollator':
            return 124;
          case 'stroller':
            return 125;
          default:
            return 11;
        }
      };

      FeedbackMessage.prototype.validate = function(attrs, options) {
        if (attrs.description === '') {
          return {
            description: 'description_required'
          };
        } else if (attrs.description.trim().length < 10) {
          this.set('description', attrs.description);
          return {
            description: 'description_length'
          };
        }
      };

      FeedbackMessage.prototype.serialize = function() {
        var json, service_code, viewpoints;
        json = _.pick(this.toJSON(), 'title', 'first_name', 'description', 'email', 'service_request_type', 'can_be_published');
        viewpoints = this.get('accessibility_viewpoints');
        if (viewpoints != null ? viewpoints.length : void 0) {
          service_code = this._serviceCodeFromPersonalisation(viewpoints[0]);
        } else {
          if (this.get('accessibility_enabled')) {
            service_code = 11;
          } else {
            service_code = 1363;
          }
        }
        json.service_code = service_code;
        json.service_object_id = this.get('unit').get('id');
        json.service_object_type = 'http://www.hel.fi/servicemap/v2';
        return json;
      };

      FeedbackMessage.prototype.sync = function(method, model, options) {
        var json;
        json = this.serialize();
        if (!this.validationError) {
          if (method === 'create') {
            return $.post(this.urlRoot(), this.serialize(), (function(_this) {
              return function() {
                return _this.trigger('sent');
              };
            })(this));
          }
        }
      };

      FeedbackMessage.prototype.urlRoot = function() {
        return OPEN311_WRITE_BASE;
      };

      return FeedbackMessage;

    })(SMModel);
    exports = {
      Unit: Unit,
      Service: Service,
      UnitList: UnitList,
      Department: Department,
      DepartmentList: DepartmentList,
      Organization: Organization,
      OrganizationList: OrganizationList,
      ServiceList: ServiceList,
      AdministrativeDivision: AdministrativeDivision,
      AdministrativeDivisionList: AdministrativeDivisionList,
      AdministrativeDivisionType: AdministrativeDivisionType,
      AdministrativeDivisionTypeList: AdministrativeDivisionTypeList,
      SearchList: SearchList,
      Language: Language,
      LanguageList: LanguageList,
      Event: Event,
      WrappedModel: WrappedModel,
      EventList: EventList,
      RoutingParameters: RoutingParameters,
      Position: Position,
      CoordinatePosition: CoordinatePosition,
      AddressPosition: AddressPosition,
      PositionList: PositionList,
      AddressList: AddressList,
      FeedbackItem: FeedbackItem,
      FeedbackList: FeedbackList,
      FeedbackMessage: FeedbackMessage,
      Street: Street,
      StreetList: StreetList
    };
    window.models = exports;
    return exports;
  });

}).call(this);

//# sourceMappingURL=models.js.map
