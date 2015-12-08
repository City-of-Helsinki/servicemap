(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  define(['underscore', 'i18next', 'cs!app/models', 'cs!app/views/base', 'cs!app/views/radius', 'cs!app/spinner'], function(_, i18n, models, base, RadiusControlsView, SMSpinner) {
    var BaseListingLayoutView, EXPAND_CUTOFF, LocationPromptView, PAGE_SIZE, RESULT_TYPES, SearchLayoutView, SearchResultView, SearchResultsLayoutView, SearchResultsView, UnitListLayoutView, isElementInViewport;
    RESULT_TYPES = {
      unit: models.UnitList,
      service: models.ServiceList,
      address: models.PositionList
    };
    EXPAND_CUTOFF = 3;
    PAGE_SIZE = 20;
    isElementInViewport = function(el) {
      var rect;
      if (typeof jQuery === 'function' && el instanceof jQuery) {
        el = el[0];
      }
      rect = el.getBoundingClientRect();
      return rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) + (el.offsetHeight * 0);
    };
    SearchResultView = (function(_super) {
      __extends(SearchResultView, _super);

      function SearchResultView() {
        return SearchResultView.__super__.constructor.apply(this, arguments);
      }

      SearchResultView.prototype.template = 'search-result';

      SearchResultView.prototype.tagName = 'li';

      SearchResultView.prototype.events = function() {
        var keyhandler;
        keyhandler = this.keyboardHandler(this.selectResult, ['enter']);
        return {
          'click': 'selectResult',
          'keydown': keyhandler,
          'focus': 'highlightResult',
          'mouseenter': 'highlightResult'
        };
      };

      SearchResultView.prototype.initialize = function(opts) {
        return this.order = opts.order;
      };

      SearchResultView.prototype.selectResult = function(ev) {
        var object_type;
        object_type = this.model.get('object_type') || 'unit';
        switch (object_type) {
          case 'unit':
            return app.commands.execute('selectUnit', this.model);
          case 'service':
            return app.commands.execute('addService', this.model);
          case 'address':
            return app.commands.execute('selectPosition', this.model);
        }
      };

      SearchResultView.prototype.highlightResult = function(ev) {
        return app.commands.execute('highlightUnit', this.model);
      };

      SearchResultView.prototype.serializeData = function() {
        var data, fn;
        data = SearchResultView.__super__.serializeData.call(this);
        data.specifier_text = this.model.getSpecifierText();
        switch (this.order) {
          case 'distance':
            fn = this.model.getDistanceToLastPosition;
            if (fn != null) {
              data.distance = fn.apply(this.model);
            }
            break;
          case 'accessibility':
            fn = this.model.getShortcomingCount;
            if (fn != null) {
              data.shortcomings = fn.apply(this.model);
            }
        }
        if (this.model.get('object_type') === 'address') {
          data.name = this.model.humanAddress({
            exclude: {
              municipality: true
            }
          });
        }
        return data;
      };

      return SearchResultView;

    })(base.SMItemView);
    SearchResultsView = (function(_super) {
      __extends(SearchResultsView, _super);

      function SearchResultsView() {
        return SearchResultsView.__super__.constructor.apply(this, arguments);
      }

      SearchResultsView.prototype.tagName = 'ul';

      SearchResultsView.prototype.className = 'main-list';

      SearchResultsView.prototype.itemView = SearchResultView;

      SearchResultsView.prototype.itemViewOptions = function() {
        return {
          order: this.parent.getComparatorKey()
        };
      };

      SearchResultsView.prototype.initialize = function(opts) {
        SearchResultsView.__super__.initialize.call(this, opts);
        return this.parent = opts.parent;
      };

      return SearchResultsView;

    })(base.SMCollectionView);
    LocationPromptView = (function(_super) {
      __extends(LocationPromptView, _super);

      function LocationPromptView() {
        return LocationPromptView.__super__.constructor.apply(this, arguments);
      }

      LocationPromptView.prototype.tagName = 'ul';

      LocationPromptView.prototype.className = 'main-list';

      LocationPromptView.prototype.render = function() {
        this.$el.html("<li>" + (i18n.t('search.location_info')) + "</li>");
        return this;
      };

      return LocationPromptView;

    })(base.SMItemView);
    SearchResultsLayoutView = (function(_super) {
      __extends(SearchResultsLayoutView, _super);

      function SearchResultsLayoutView() {
        return SearchResultsLayoutView.__super__.constructor.apply(this, arguments);
      }

      SearchResultsLayoutView.prototype.template = 'search-results';

      SearchResultsLayoutView.prototype.regions = {
        results: '.result-contents',
        controls: '#list-controls'
      };

      SearchResultsLayoutView.prototype.className = 'search-results-container';

      SearchResultsLayoutView.prototype.events = {
        'click .back-button': 'goBack',
        'click .sorting': 'cycleSorting'
      };

      SearchResultsLayoutView.prototype.goBack = function(ev) {
        this.expansion = EXPAND_CUTOFF;
        this.requestedExpansion = 0;
        return this.parent.backToSummary();
      };

      SearchResultsLayoutView.prototype.cycleSorting = function(ev) {
        var key;
        this.fullCollection.cycleComparator();
        key = this.fullCollection.getComparatorKey();
        this.renderLocationPrompt = false;
        if (key === 'distance') {
          if (p13n.getLastPosition() == null) {
            this.renderLocationPrompt = true;
            this.listenTo(p13n, 'position', (function(_this) {
              return function() {
                _this.renderLocationPrompt = false;
                return _this.fullCollection.sort();
              };
            })(this));
            this.listenTo(p13n, 'position_error', (function(_this) {
              return function() {
                return _this.renderLocationPrompt = false;
              };
            })(this));
            p13n.requestLocation();
          }
        }
        this.expansion = 2 * PAGE_SIZE;
        return this.render();
      };

      SearchResultsLayoutView.prototype.onBeforeRender = function() {
        return this.collection = new this.fullCollection.constructor(this.fullCollection.slice(0, this.expansion));
      };

      SearchResultsLayoutView.prototype.nextPage = function(ev) {
        var delta, newExpansion;
        if (this.expansion === EXPAND_CUTOFF) {
          delta = 2 * PAGE_SIZE - EXPAND_CUTOFF;
        } else {
          delta = PAGE_SIZE;
        }
        newExpansion = this.expansion + delta;
        if (this.requestedExpansion === newExpansion) {
          return;
        }
        this.requestedExpansion = newExpansion;
        this.expansion = this.requestedExpansion;
        return this.render();
      };

      SearchResultsLayoutView.prototype.getDetailedFieldset = function() {
        switch (this.resultType) {
          case 'unit':
            return ['services'];
          case 'service':
            return ['ancestors'];
          default:
            return null;
        }
      };

      SearchResultsLayoutView.prototype.initialize = function(_arg) {
        var _ref;
        this.collectionType = _arg.collectionType, this.fullCollection = _arg.fullCollection, this.resultType = _arg.resultType, this.parent = _arg.parent, this.onlyResultType = _arg.onlyResultType, this.position = _arg.position;
        this.expansion = EXPAND_CUTOFF;
        this.$more = null;
        this.requestedExpansion = 0;
        this.ready = false;
        this.ready = true;
        if (this.onlyResultType) {
          this.expansion = 2 * PAGE_SIZE;
          if ((_ref = this.parent) != null) {
            _ref.expand(this.resultType);
          }
        }
        this.listenTo(this.fullCollection, 'hide', (function(_this) {
          return function() {
            _this.hidden = true;
            return _this.render();
          };
        })(this));
        this.listenTo(this.fullCollection, 'show-all', this.nextPage);
        this.listenTo(this.fullCollection, 'sort', this.render);
        this.listenTo(this.fullCollection, 'batch-remove', this.render);
        return this.listenTo(p13n, 'accessibility-change', (function(_this) {
          return function() {
            var key;
            key = _this.fullCollection.getComparatorKey();
            if (p13n.hasAccessibilityIssues()) {
              _this.fullCollection.setComparator('accessibility');
            } else if (key === 'accessibility') {
              _this.fullCollection.setDefaultComparator();
            }
            _this.fullCollection.sort();
            return _this.render();
          };
        })(this));
      };

      SearchResultsLayoutView.prototype.getComparatorKey = function() {
        return this.fullCollection.getComparatorKey();
      };

      SearchResultsLayoutView.prototype.serializeData = function() {
        var crumb, data;
        if (this.hidden || (this.collection == null)) {
          return {
            hidden: true
          };
        }
        data = SearchResultsLayoutView.__super__.serializeData.call(this);
        if (this.collection.length) {
          crumb = (function() {
            switch (this.collectionType) {
              case 'search':
                return i18n.t('sidebar.search_results');
              case 'radius':
                if (this.position != null) {
                  return this.position.humanAddress();
                }
            }
          }).call(this);
          data = {
            comparatorKey: this.fullCollection.getComparatorKey(),
            controls: this.collectionType === 'radius',
            target: this.resultType,
            expanded: this._expanded(),
            showAll: false,
            showMore: false,
            onlyResultType: this.onlyResultType,
            crumb: crumb,
            header: i18n.t("search.type." + this.resultType + ".count", {
              count: this.fullCollection.length
            })
          };
          if (this.fullCollection.length > EXPAND_CUTOFF && !this._expanded()) {
            data.showAll = i18n.t("search.type." + this.resultType + ".show_all", {
              count: this.fullCollection.length
            });
          } else if (this.fullCollection.length > this.expansion && !this.renderLocationPrompt) {
            data.showMore = true;
          }
        }
        return data;
      };

      SearchResultsLayoutView.prototype.onRender = function() {
        var collectionView;
        if (this.renderLocationPrompt) {
          this.results.show(new LocationPromptView());
          return;
        }
        if (!this.ready) {
          this.ready = true;
          return;
        }
        collectionView = new SearchResultsView({
          collection: this.collection,
          parent: this
        });
        this.listenTo(collectionView, 'collection:rendered', (function(_this) {
          return function() {
            return _.defer(function() {
              _this.$more = $(_this.el).find('.show-more');
              _this.tryNextPage();
              return _this.trigger('rendered');
            });
          };
        })(this));
        this.results.show(collectionView);
        if (this.collectionType === 'radius') {
          return this.controls.show(new RadiusControlsView({
            radius: this.fullCollection.filters.distance
          }));
        }
      };

      SearchResultsLayoutView.prototype.tryNextPage = function() {
        var spinner, _ref;
        if ((_ref = this.$more) != null ? _ref.length : void 0) {
          if (isElementInViewport(this.$more)) {
            this.$more.find('.text-content').html(i18n.t('accessibility.pending'));
            spinner = new SMSpinner({
              container: this.$more.find('.spinner-container').get(0),
              radius: 5,
              length: 3,
              lines: 12,
              width: 2
            });
            spinner.start();
            return this.nextPage();
          }
        }
      };

      SearchResultsLayoutView.prototype._expanded = function() {
        return this.expansion > EXPAND_CUTOFF;
      };

      return SearchResultsLayoutView;

    })(base.SMLayout);
    BaseListingLayoutView = (function(_super) {
      __extends(BaseListingLayoutView, _super);

      function BaseListingLayoutView() {
        return BaseListingLayoutView.__super__.constructor.apply(this, arguments);
      }

      BaseListingLayoutView.prototype.className = function() {
        return 'search-results navigation-element limit-max-height';
      };

      BaseListingLayoutView.prototype.events = function() {
        return {
          'scroll': 'tryNextPage'
        };
      };

      BaseListingLayoutView.prototype.onRender = function() {
        var view;
        view = this.getPrimaryResultLayoutView();
        if (view == null) {
          return;
        }
        return this.listenToOnce(view, 'rendered', (function(_this) {
          return function() {
            return _.defer(function() {
              return _this.$el.find('.search-result').first().focus();
            });
          };
        })(this));
      };

      return BaseListingLayoutView;

    })(base.SMLayout);
    UnitListLayoutView = (function(_super) {
      __extends(UnitListLayoutView, _super);

      function UnitListLayoutView() {
        return UnitListLayoutView.__super__.constructor.apply(this, arguments);
      }

      UnitListLayoutView.prototype.template = 'service-units';

      UnitListLayoutView.prototype.regions = {
        'unitRegion': '.unit-region'
      };

      UnitListLayoutView.prototype.tryNextPage = function() {
        return this.resultLayoutView.tryNextPage();
      };

      UnitListLayoutView.prototype.initialize = function() {
        var opts, rest;
        opts = arguments[0], rest = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return this.resultLayoutView = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(SearchResultsLayoutView, [opts].concat(__slice.call(rest)), function(){});
      };

      UnitListLayoutView.prototype.onRender = function() {
        this.unitRegion.show(this.resultLayoutView);
        return UnitListLayoutView.__super__.onRender.call(this);
      };

      UnitListLayoutView.prototype.getPrimaryResultLayoutView = function() {
        return this.resultLayoutView;
      };

      return UnitListLayoutView;

    })(BaseListingLayoutView);
    SearchLayoutView = (function(_super) {
      __extends(SearchLayoutView, _super);

      function SearchLayoutView() {
        return SearchLayoutView.__super__.constructor.apply(this, arguments);
      }

      SearchLayoutView.prototype.template = 'search-layout';

      SearchLayoutView.prototype.type = 'search';

      SearchLayoutView.prototype.events = function() {
        return _.extend({}, SearchLayoutView.__super__.events.call(this), {
          'click .show-all': 'showAllOfSingleType'
        });
      };

      SearchLayoutView.prototype.tryNextPage = function() {
        var _ref;
        if (this.expanded) {
          return (_ref = this.resultLayoutViews[this.expanded]) != null ? _ref.tryNextPage() : void 0;
        }
      };

      SearchLayoutView.prototype.expand = function(target) {
        return this.expanded = target;
      };

      SearchLayoutView.prototype.showAllOfSingleType = function(ev) {
        var target;
        if (ev != null) {
          ev.preventDefault();
        }
        target = $(ev.currentTarget).data('target');
        this.expanded = target;
        return _(this.collections).each((function(_this) {
          return function(collection, key) {
            if (key === target) {
              return collection.trigger('show-all');
            } else {
              return collection.trigger('hide');
            }
          };
        })(this));
      };

      SearchLayoutView.prototype.backToSummary = function() {
        this.expanded = null;
        return this.render();
      };

      SearchLayoutView.prototype._regionId = function(key) {
        return "" + key + "Region";
      };

      SearchLayoutView.prototype._getRegionForType = function(key) {
        return this.getRegion(this._regionId(key));
      };

      SearchLayoutView.prototype.initialize = function() {
        this.expanded = null;
        this.collections = {};
        this.resultLayoutViews = {};
        _(RESULT_TYPES).each((function(_this) {
          return function(val, key) {
            _this.collections[key] = new val(null, {
              setComparator: true
            });
            return _this.addRegion(_this._regionId(key), "." + key + "-region");
          };
        })(this));
        return this.listenTo(this.collection, 'hide', (function(_this) {
          return function() {
            return _this.$el.hide();
          };
        })(this));
      };

      SearchLayoutView.prototype.serializeData = function() {
        var data;
        data = SearchLayoutView.__super__.serializeData.call(this);
        _(RESULT_TYPES).each((function(_this) {
          return function(__, key) {
            return _this.collections[key].set(_this.collection.where({
              object_type: key
            }));
          };
        })(this));
        if (!this.collection.length) {
          if (this.collection.query) {
            data.noResults = true;
            data.query = this.collection.query;
          }
        }
        return data;
      };

      SearchLayoutView.prototype.getPrimaryResultLayoutView = function() {
        return this.resultLayoutViews['unit'];
      };

      SearchLayoutView.prototype.onRender = function() {
        var resultTypeCount;
        this.$el.show();
        resultTypeCount = _(this.collections).filter((function(_this) {
          return function(c) {
            return c.length > 0;
          };
        })(this)).length;
        _(RESULT_TYPES).each((function(_this) {
          return function(__, key) {
            if (_this.collections[key].length) {
              _this.resultLayoutViews[key] = new SearchResultsLayoutView({
                resultType: key,
                collectionType: 'search',
                fullCollection: _this.collections[key],
                onlyResultType: resultTypeCount === 1,
                parent: _this
              });
              return _this._getRegionForType(key).show(_this.resultLayoutViews[key]);
            }
          };
        })(this));
        return SearchLayoutView.__super__.onRender.call(this);
      };

      return SearchLayoutView;

    })(BaseListingLayoutView);
    return {
      SearchLayoutView: SearchLayoutView,
      UnitListLayoutView: UnitListLayoutView
    };
  });

}).call(this);

//# sourceMappingURL=search-results.js.map
