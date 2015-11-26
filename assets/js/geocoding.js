(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['cs!app/base', 'cs!app/p13n', 'cs!app/settings', 'cs!app/jade', 'cs!app/models', 'typeahead.bundle', 'backbone'], function(sm, p13n, settings, jade, models, _typeahead, Backbone) {
    var GeocoderSourceBackend, monkeyPatchTypeahead;
    monkeyPatchTypeahead = (function(_this) {
      return function($element) {
        var originalSelect, proto, typeahead;
        typeahead = $element.data('ttTypeahead');
        proto = Object.getPrototypeOf(typeahead);
        originalSelect = proto._select;
        proto._select = function(datum) {
          this.input.setQuery(datum.value);
          this.input.setInputValue(datum.value, true);
          this._setLanguageDirection();
          return this.eventBus.trigger('selected', datum.raw, datum.datasetName);
        };
        return proto.closeCompletely = function() {
          this.close();
          return _.defer(_.bind(this.dropdown.empty, this.dropdown));
        };
      };
    })(this);
    return {
      GeocoderSourceBackend: GeocoderSourceBackend = (function() {
        function GeocoderSourceBackend(options) {
          var geocoderStreetEngine;
          this.options = options;
          this.getDatasetOptions = __bind(this.getDatasetOptions, this);
          this.getSource = __bind(this.getSource, this);
          this.addressSource = __bind(this.addressSource, this);
          this.setStreet = __bind(this.setStreet, this);
          _.extend(this, Backbone.Events);
          this.street = void 0;
          geocoderStreetEngine = this._createGeocoderStreetEngine(p13n.getLanguage());
          this.geocoderStreetSource = geocoderStreetEngine.ttAdapter();
        }

        GeocoderSourceBackend.prototype.setOptions = function(options) {
          this.options = options;
          this.options.$inputEl.on('typeahead:selected', _.bind(this.typeaheadSelected, this));
          this.options.$inputEl.on('typeahead:autocompleted', _.bind(this.typeaheadSelected, this));
          return monkeyPatchTypeahead(this.options.$inputEl);
        };

        GeocoderSourceBackend.prototype._createGeocoderStreetEngine = function(lang) {
          var e;
          e = new Bloodhound({
            name: 'street_suggestions',
            remote: {
              url: appSettings.service_map_backend + "/street/?page_size=4",
              replace: (function(_this) {
                return function(url, query) {
                  url += "&input=" + query;
                  url += "&language=" + (lang !== 'sv' ? 'fi' : lang);
                  return url;
                };
              })(this),
              ajax: settings.applyAjaxDefaults({}),
              filter: (function(_this) {
                return function(parsedResponse) {
                  var results;
                  results = new models.StreetList(parsedResponse.results);
                  if (results.length === 1) {
                    _this.setStreet(results.first());
                  }
                  return results.toArray();
                };
              })(this),
              rateLimitWait: 50
            },
            datumTokenizer: function(datum) {
              return Bloodhound.tokenizers.whitespace(datum.name[lang]);
            },
            queryTokenizer: (function(_this) {
              return function(s) {
                var res;
                return res = [s];
              };
            })(this)
          });
          e.initialize();
          return e;
        };

        GeocoderSourceBackend.prototype.typeaheadSelected = function(ev, data) {
          var objectType;
          objectType = data.object_type;
          if (objectType === 'address') {
            if (data instanceof models.Position) {
              this.options.$inputEl.typeahead('close');
              return this.options.selectionCallback(ev, data);
            } else {
              return this.setStreet(data).done((function(_this) {
                return function() {
                  _this.options.$inputEl.val(_this.options.$inputEl.val() + ' ');
                  return _this.options.$inputEl.trigger('input');
                };
              })(this));
            }
          } else {
            return this.setStreet(null);
          }
        };

        GeocoderSourceBackend.prototype.streetSelected = function() {
          if (this.street == null) {
            return;
          }
          return _.defer((function(_this) {
            return function() {
              var streetName;
              streetName = p13n.getTranslatedAttr(_this.street.name);
              _this.options.$inputEl.typeahead('val', '');
              _this.options.$inputEl.typeahead('val', streetName + ' ');
              return _this.options.$inputEl.trigger('input');
            };
          })(this));
        };

        GeocoderSourceBackend.prototype.setStreet = function(street) {
          return sm.withDeferred((function(_this) {
            return function(deferred) {
              var _ref;
              if (street == null) {
                _this.street = void 0;
                deferred.resolve();
                return;
              }
              if (street.get('id') === ((_ref = _this.street) != null ? _ref.get('id') : void 0)) {
                deferred.resolve();
                return;
              }
              _this.street = street;
              _this.street.translatedName = (_this.street.get('name')[p13n.getLanguage()] || _this.street.get('name').fi).toLowerCase();
              _this.street.addresses = new models.AddressList([], {
                pageSize: 200
              });
              _this.street.addresses.comparator = function(x) {
                return parseInt(x.get('number'));
              };
              _this.street.addressesFetched = false;
              return _this.street.addresses.fetch({
                data: {
                  street: _this.street.get('id')
                },
                success: function() {
                  var _ref1;
                  if ((_ref1 = _this.street) != null) {
                    _ref1.addressesFetched = true;
                  }
                  return deferred.resolve();
                }
              });
            };
          })(this));
        };

        GeocoderSourceBackend.prototype.addressSource = function(query, callback) {
          var done, matches, numberPart, q, re;
          re = new RegExp("^\\s*" + this.street.translatedName + "(\\s+\\d.*)?", 'i');
          matches = query.match(re);
          if (matches != null) {
            q = matches[0], numberPart = matches[1];
            if (numberPart == null) {
              numberPart = '';
            }
            numberPart = numberPart.replace(/\s+/g, '').replace(/[^0-9]+/g, '');
            done = (function(_this) {
              return function() {
                var filtered, last, results;
                if (_this.street == null) {
                  callback([]);
                  return;
                }
                if (_this.street.addresses.length === 1) {
                  callback(_this.street.addresses.toArray());
                  return;
                }
                filtered = _this.street.addresses.filter(function(a) {
                  return a.humanNumber().indexOf(numberPart) === 0;
                });
                results = filtered.slice(0, 2);
                last = _(filtered).last();
                if (__indexOf.call(results, last) < 0) {
                  if (last != null) {
                    results.push(last);
                  }
                }
                return callback(results);
              };
            })(this);
            if (this.street.addressesFetched) {
              return done();
            } else {
              return this.listenToOnce(this.street.addresses, 'sync', (function(_this) {
                return function() {
                  return done();
                };
              })(this));
            }
          }
        };

        GeocoderSourceBackend.prototype.getSource = function() {
          return (function(_this) {
            return function(query, cb) {
              if ((_this.street != null) && _this.street.translatedName.length <= query.length) {
                return _this.addressSource(query, cb);
              } else {
                return _this.geocoderStreetSource(query, cb);
              }
            };
          })(this);
        };

        GeocoderSourceBackend.prototype.getDatasetOptions = function() {
          return {
            name: 'address',
            displayKey: function(c) {
              return c.humanAddress();
            },
            source: this.getSource(),
            templates: {
              suggestion: (function(_this) {
                return function(c) {
                  if (c instanceof models.Position) {
                    c.set('street', _this.street);
                  }
                  c.address = c.humanAddress();
                  c.object_type = 'address';
                  return jade.template('typeahead-suggestion', c);
                };
              })(this)
            }
          };
        };

        return GeocoderSourceBackend;

      })()
    };
  });

}).call(this);

//# sourceMappingURL=geocoding.js.map
