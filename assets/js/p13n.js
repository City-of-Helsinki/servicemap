(function() {
  var SUPPORTED_LANGUAGES, lang, makeMomentLang, momentDeps, p13nDeps,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  SUPPORTED_LANGUAGES = ['fi', 'en', 'sv'];

  makeMomentLang = function(lang) {
    if (lang === 'en') {
      return 'en-gb';
    }
    return lang;
  };

  momentDeps = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = SUPPORTED_LANGUAGES.length; _i < _len; _i++) {
      lang = SUPPORTED_LANGUAGES[_i];
      _results.push("moment/" + (makeMomentLang(lang)));
    }
    return _results;
  })();

  p13nDeps = ['module', 'cs!app/models', 'underscore', 'backbone', 'i18next', 'moment'].concat(momentDeps);

  define(p13nDeps, function(module, models, _, Backbone, i18n, moment) {
    var ACCESSIBILITY_GROUPS, ALLOWED_VALUES, CURRENT_VERSION, DEFAULTS, FALLBACK_LANGUAGES, LANGUAGE_NAMES, LOCALSTORAGE_KEY, PROFILE_IDS, ServiceMapPersonalization, deepExtend;
    LOCALSTORAGE_KEY = 'servicemap_p13n';
    CURRENT_VERSION = 1;
    LANGUAGE_NAMES = {
      fi: 'suomi',
      sv: 'svenska',
      en: 'English'
    };
    FALLBACK_LANGUAGES = ['en', 'fi'];
    ACCESSIBILITY_GROUPS = {
      senses: ['hearing_aid', 'visually_impaired', 'colour_blind'],
      mobility: ['wheelchair', 'reduced_mobility', 'rollator', 'stroller']
    };
    ALLOWED_VALUES = {
      accessibility: {
        mobility: [null, 'wheelchair', 'reduced_mobility', 'rollator', 'stroller']
      },
      transport: ['by_foot', 'bicycle', 'public_transport', 'car'],
      transport_detailed_choices: {
        "public": ['bus', 'tram', 'metro', 'train', 'ferry'],
        bicycle: ['bicycle_parked', 'bicycle_with']
      },
      language: SUPPORTED_LANGUAGES,
      map_background_layer: ['servicemap', 'ortographic', 'guidemap', 'accessible_map'],
      city: [null, 'helsinki', 'espoo', 'vantaa', 'kauniainen']
    };
    PROFILE_IDS = {
      'wheelchair': 1,
      'reduced_mobility': 2,
      'rollator': 3,
      'stroller': 4,
      'visually_impaired': 5,
      'hearing_aid': 6
    };
    DEFAULTS = {
      language: appSettings.default_language,
      first_visit: true,
      skip_tour: false,
      hide_tour: false,
      location_requested: false,
      map_background_layer: 'servicemap',
      accessibility: {
        hearing_aid: false,
        visually_impaired: false,
        colour_blind: false,
        mobility: null
      },
      city: null,
      transport: {
        by_foot: false,
        bicycle: false,
        public_transport: true,
        car: false
      },
      transport_detailed_choices: {
        "public": {
          bus: true,
          tram: true,
          metro: true,
          train: true,
          ferry: true
        },
        bicycle: {
          bicycle_parked: true,
          bicycle_with: false
        }
      }
    };
    deepExtend = function(target, source, allowedValues) {
      var prop, sourceIsObject, targetIsObject, _ref, _results;
      _results = [];
      for (prop in target) {
        if (!(prop in source)) {
          continue;
        }
        sourceIsObject = !!source[prop] && typeof source[prop] === 'object';
        targetIsObject = !!target[prop] && typeof target[prop] === 'object';
        if (targetIsObject !== sourceIsObject) {
          console.error("Value mismatch for " + prop + ": " + (typeof source[prop]) + " vs. " + (typeof target[prop]));
          continue;
        }
        if (targetIsObject) {
          deepExtend(target[prop], source[prop], allowedValues[prop] || {});
          continue;
        }
        if (prop in allowedValues) {
          if (_ref = target[prop], __indexOf.call(allowedValues[prop], _ref) < 0) {
            console.error("Invalid value for " + prop + ": " + target[prop]);
            continue;
          }
        }
        _results.push(target[prop] = source[prop]);
      }
      return _results;
    };
    ServiceMapPersonalization = (function() {
      function ServiceMapPersonalization() {
        this._handleLocationError = __bind(this._handleLocationError, this);
        this._handleLocation = __bind(this._handleLocation, this);
        this.testLocalStorageEnabled = __bind(this.testLocalStorageEnabled, this);
        _.extend(this, Backbone.Events);
        this.attributes = _.clone(DEFAULTS);
        if (module.config().localStorageEnabled === false) {
          this.localStorageEnabled = false;
        } else {
          this.localStorageEnabled = this.testLocalStorageEnabled();
        }
        this._fetch();
        this.deferred = i18n.init({
          lng: this.getLanguage(),
          resGetPath: appSettings.static_path + 'locales/__lng__.json',
          fallbackLng: FALLBACK_LANGUAGES
        });
        i18n.addPostProcessor("fixFinnishStreetNames", function(value, key, options) {
          var REPLACEMENTS, grammaticalCase, replacement, rules, _i, _len;
          REPLACEMENTS = {
            "_allatiivi_": [[/katu$/, "kadulle"], [/polku$/, "polulle"], [/ranta$/, "rannalle"], [/ramppia$/, "rampille"], [/$/, "lle"]],
            "_partitiivi_": [[/tie$/, "tietä"], [/Kehä I/, "Kehä I:tä"], [/Kehä III/, "Kehä III:a"], [/ä$/, "ää"], [/$/, "a"]]
          };
          for (grammaticalCase in REPLACEMENTS) {
            rules = REPLACEMENTS[grammaticalCase];
            if (value.indexOf(grammaticalCase) > -1) {
              for (_i = 0, _len = rules.length; _i < _len; _i++) {
                replacement = rules[_i];
                if (options.street.match(replacement[0])) {
                  options.street = options.street.replace(replacement[0], replacement[1]);
                  return value.replace(grammaticalCase, options.street);
                }
              }
            }
          }
        });
        moment.locale(makeMomentLang(this.getLanguage()));
        window.i18nDebug = i18n;
      }

      ServiceMapPersonalization.prototype.testLocalStorageEnabled = function() {
        var e, val;
        val = '_test';
        try {
          localStorage.setItem(val, val);
          localStorage.removeItem(val);
          return true;
        } catch (_error) {
          e = _error;
          return false;
        }
      };

      ServiceMapPersonalization.prototype._handleLocation = function(pos, positionObject) {
        var cb;
        if (pos.coords.accuracy > 10000) {
          this.trigger('position_error');
          return;
        }
        if (positionObject == null) {
          positionObject = new models.CoordinatePosition({
            isDetected: true
          });
        }
        cb = (function(_this) {
          return function() {
            var coords;
            coords = pos['coords'];
            positionObject.set('location', {
              coordinates: [coords.longitude, coords.latitude]
            });
            positionObject.set('accuracy', pos.coords.accuracy);
            _this.lastPosition = positionObject;
            _this.trigger('position', positionObject);
            if (!_this.get('location_requested')) {
              return _this.set('location_requested', true);
            }
          };
        })(this);
        if (appSettings.user_location_delayed) {
          return setTimeout(cb, 3000);
        } else {
          return cb();
        }
      };

      ServiceMapPersonalization.prototype._handleLocationError = function(error) {
        this.trigger('position_error');
        return this.set('location_requested', false);
      };

      ServiceMapPersonalization.prototype.setVisited = function() {
        return this._setValue(['first_visit'], false);
      };

      ServiceMapPersonalization.prototype.getLastPosition = function() {
        return this.lastPosition;
      };

      ServiceMapPersonalization.prototype.getLocationRequested = function() {
        return this.get('location_requested');
      };

      ServiceMapPersonalization.prototype._setValue = function(path, val) {
        var allowed, dirs, name, oldVal, pathStr, propName, vars, _i, _len;
        pathStr = path.join('.');
        vars = this.attributes;
        allowed = ALLOWED_VALUES;
        dirs = path.slice(0);
        propName = dirs.pop();
        for (_i = 0, _len = dirs.length; _i < _len; _i++) {
          name = dirs[_i];
          if (!(name in vars)) {
            throw new Error("Attempting to set invalid variable name: " + pathStr);
          }
          vars = vars[name];
          if (!allowed) {
            continue;
          }
          if (!(name in allowed)) {
            allowed = null;
            continue;
          }
          allowed = allowed[name];
        }
        if (allowed && propName in allowed) {
          if (__indexOf.call(allowed[propName], val) < 0) {
            throw new Error("Invalid value for " + pathStr + ": " + val);
          }
        } else if (typeof val !== 'boolean') {
          throw new Error("Invalid value for " + pathStr + ": " + val + " (should be boolean)");
        }
        oldVal = vars[propName];
        if (oldVal === val) {
          return;
        }
        vars[propName] = val;
        this._save();
        this.trigger('change', path, val);
        if (path[0] === 'accessibility') {
          this.trigger('accessibility-change');
        }
        return val;
      };

      ServiceMapPersonalization.prototype.toggleMobility = function(val) {
        var oldVal;
        oldVal = this.getAccessibilityMode('mobility');
        if (val === oldVal) {
          return this._setValue(['accessibility', 'mobility'], null);
        } else {
          return this._setValue(['accessibility', 'mobility'], val);
        }
      };

      ServiceMapPersonalization.prototype.toggleAccessibilityMode = function(modeName) {
        var oldVal;
        oldVal = this.getAccessibilityMode(modeName);
        return this._setValue(['accessibility', modeName], !oldVal);
      };

      ServiceMapPersonalization.prototype.setAccessibilityMode = function(modeName, val) {
        return this._setValue(['accessibility', modeName], val);
      };

      ServiceMapPersonalization.prototype.getAccessibilityMode = function(modeName) {
        var accVars;
        accVars = this.get('accessibility');
        if (!modeName in accVars) {
          throw new Error("Attempting to get invalid accessibility mode: " + modeName);
        }
        return accVars[modeName];
      };

      ServiceMapPersonalization.prototype.toggleCity = function(val) {
        var oldVal;
        oldVal = this.get('city');
        if (val === oldVal) {
          val = null;
        }
        return this._setValue(['city'], val);
      };

      ServiceMapPersonalization.prototype.getAllAccessibilityProfileIds = function() {
        var ids, name, rawIds, rid, s, suffixes, _i, _len;
        rawIds = _.invert(PROFILE_IDS);
        ids = {};
        for (rid in rawIds) {
          name = rawIds[rid];
          suffixes = (function() {
            switch (false) {
              case !_.contains(["1", "2", "3"], rid):
                return ['A', 'B', 'C'];
              case !_.contains(["4", "6"], rid):
                return ['A'];
              case "5" !== rid:
                return ['A', 'B'];
            }
          })();
          for (_i = 0, _len = suffixes.length; _i < _len; _i++) {
            s = suffixes[_i];
            ids[rid + s] = name;
          }
        }
        return ids;
      };

      ServiceMapPersonalization.prototype.getAccessibilityProfileIds = function(filterTransit) {
        var accVars, disabilities, disability, ids, key, mobility, transport, val, _i, _len;
        ids = {};
        accVars = this.get('accessibility');
        transport = this.get('transport');
        mobility = accVars['mobility'];
        key = PROFILE_IDS[mobility];
        if (key) {
          if (key === 1 || key === 2 || key === 3 || key === 5) {
            key += transport.car ? 'B' : 'A';
          } else {
            key += 'A';
          }
          ids[key] = mobility;
        }
        disabilities = ['visually_impaired'];
        if (!filterTransit) {
          disabilities.push('hearing_aid');
        }
        for (_i = 0, _len = disabilities.length; _i < _len; _i++) {
          disability = disabilities[_i];
          val = this.getAccessibilityMode(disability);
          if (val) {
            key = PROFILE_IDS[disability];
            if (disability === 'visually_impaired') {
              key += transport.car ? 'B' : 'A';
            } else {
              key += 'A';
            }
            ids[key] = disability;
          }
        }
        return ids;
      };

      ServiceMapPersonalization.prototype.hasAccessibilityIssues = function() {
        var ids;
        ids = this.getAccessibilityProfileIds();
        return _.size(ids) > 0;
      };

      ServiceMapPersonalization.prototype.setTransport = function(modeName, val) {
        var m, modes, otherActive;
        modes = this.get('transport');
        if (val) {
          if (modeName === 'by_foot') {
            for (m in modes) {
              modes[m] = false;
            }
          } else if (modeName === 'car' || modeName === 'bicycle') {
            for (m in modes) {
              if (m === 'public_transport') {
                continue;
              }
              modes[m] = false;
            }
          } else if (modeName === 'public_transport') {
            modes.by_foot = false;
          }
        } else {
          otherActive = false;
          for (m in modes) {
            if (m === modeName) {
              continue;
            }
            if (modes[m]) {
              otherActive = true;
              break;
            }
          }
          if (!otherActive) {
            return;
          }
        }
        return this._setValue(['transport', modeName], val);
      };

      ServiceMapPersonalization.prototype.getTransport = function(modeName) {
        var modes;
        modes = this.get('transport');
        if (!modeName in modes) {
          throw new Error("Attempting to get invalid transport mode: " + modeName);
        }
        return modes[modeName];
      };

      ServiceMapPersonalization.prototype.toggleTransport = function(modeName) {
        var oldVal;
        oldVal = this.getTransport(modeName);
        return this.setTransport(modeName, !oldVal);
      };

      ServiceMapPersonalization.prototype.toggleTransportDetails = function(group, modeName) {
        var oldVal;
        oldVal = this.get('transport_detailed_choices')[group][modeName];
        if (!oldVal) {
          if (modeName === 'bicycle_parked') {
            this.get('transport_detailed_choices')[group].bicycle_with = false;
          }
          if (modeName === 'bicycle_with') {
            this.get('transport_detailed_choices')[group].bicycle_parked = false;
          }
        }
        return this._setValue(['transport_detailed_choices', group, modeName], !oldVal);
      };

      ServiceMapPersonalization.prototype.requestLocation = function(positionModel) {
        var coords, override, posOpts;
        if (appSettings.user_location_override) {
          override = appSettings.user_location_override;
          coords = {
            latitude: override[0],
            longitude: override[1],
            accuracy: 10
          };
          this._handleLocation({
            coords: coords
          });
          return;
        }
        if (!('geolocation' in navigator)) {
          return;
        }
        posOpts = {
          enableHighAccuracy: false,
          timeout: 30000
        };
        return navigator.geolocation.getCurrentPosition(((function(_this) {
          return function(pos) {
            return _this._handleLocation(pos, positionModel);
          };
        })(this)), this._handleLocationError, posOpts);
      };

      ServiceMapPersonalization.prototype.set = function(attr, val) {
        if (!attr in this.attributes) {
          throw new Error("attempting to set invalid attribute: " + attr);
        }
        this.attributes[attr] = val;
        this.trigger('change', attr, val);
        return this._save();
      };

      ServiceMapPersonalization.prototype.get = function(attr) {
        if (!attr in this.attributes) {
          return void 0;
        }
        return this.attributes[attr];
      };

      ServiceMapPersonalization.prototype._verifyValidState = function() {
        var transportModesCount;
        transportModesCount = _.filter(this.get('transport'), _.identity).length;
        if (transportModesCount === 0) {
          return this.setTransport('public_transport', true);
        }
      };

      ServiceMapPersonalization.prototype._fetch = function() {
        var storedAttrs, str;
        if (!this.localStorageEnabled) {
          return;
        }
        str = localStorage.getItem(LOCALSTORAGE_KEY);
        if (!str) {
          return;
        }
        storedAttrs = JSON.parse(str);
        deepExtend(this.attributes, storedAttrs, ALLOWED_VALUES);
        return this._verifyValidState();
      };

      ServiceMapPersonalization.prototype._save = function() {
        var data, str;
        if (!this.localStorageEnabled) {
          return;
        }
        data = _.extend(this.attributes, {
          version: CURRENT_VERSION
        });
        str = JSON.stringify(data);
        return localStorage.setItem(LOCALSTORAGE_KEY, str);
      };

      ServiceMapPersonalization.prototype.getProfileElement = function(name) {
        return {
          icon: "icon-icon-" + (name.replace('_', '-')),
          text: i18n.t("personalisation." + name)
        };
      };

      ServiceMapPersonalization.prototype.getProfileElements = function(profiles) {
        return _.map(profiles, this.getProfileElement);
      };

      ServiceMapPersonalization.prototype.getLanguage = function() {
        return appSettings.default_language;
      };

      ServiceMapPersonalization.prototype.getTranslatedAttr = function(attr) {
        var languages, _i, _len;
        if (!attr) {
          return attr;
        }
        if (!attr instanceof Object) {
          console.error("translated attribute didn't get a translation object", attr);
          return attr;
        }
        languages = [this.getLanguage()].concat(SUPPORTED_LANGUAGES);
        for (_i = 0, _len = languages.length; _i < _len; _i++) {
          lang = languages[_i];
          if (lang in attr) {
            return attr[lang];
          }
        }
        console.error("no supported languages found", attr);
        return null;
      };

      ServiceMapPersonalization.prototype.getSupportedLanguages = function() {
        return _.map(SUPPORTED_LANGUAGES, function(l) {
          return {
            code: l,
            name: LANGUAGE_NAMES[l]
          };
        });
      };

      ServiceMapPersonalization.prototype.getHumanizedDate = function(time) {
        var diff, format, humanize, m, now, s, sod;
        m = moment(time);
        now = moment();
        sod = now.startOf('day');
        diff = m.diff(sod, 'days', true);
        if (diff < -6 || diff >= 7) {
          humanize = false;
        } else {
          humanize = true;
        }
        if (humanize) {
          s = m.calendar();
          s = s.replace(/( (klo|at))* \d{1,2}[:.]\d{1,2}$/, '');
        } else {
          if (now.year() !== m.year()) {
            format = 'L';
          } else {
            format = (function() {
              switch (this.getLanguage()) {
                case 'fi':
                  return 'Do MMMM[ta]';
                case 'en':
                  return 'D MMMM';
                case 'sv':
                  return 'D MMMM';
              }
            }).call(this);
          }
          s = m.format(format);
        }
        return s;
      };

      ServiceMapPersonalization.prototype.setMapBackgroundLayer = function(layerName) {
        return this._setValue(['map_background_layer'], layerName);
      };

      ServiceMapPersonalization.prototype.getMapBackgroundLayers = function() {
        var a;
        return a = _(ALLOWED_VALUES.map_background_layer).chain().union(['accessible_map']).map((function(_this) {
          return function(layerName) {
            return {
              name: layerName,
              selected: _this.get('map_background_layer') === layerName
            };
          };
        })(this)).value();
      };

      return ServiceMapPersonalization;

    })();
    window.p13n = new ServiceMapPersonalization;
    return window.p13n;
  });

}).call(this);

//# sourceMappingURL=p13n.js.map
