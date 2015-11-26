(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base', 'cs!app/views/event-details', 'cs!app/views/service-tree', 'cs!app/views/position-details', 'cs!app/views/unit-details', 'cs!app/views/search-input', 'cs!app/views/search-results', 'cs!app/views/sidebar-region', 'cs!app/map-view'], function(base, EventDetailsView, ServiceTreeView, PositionDetailsView, UnitDetailsView, SearchInputView, _arg, SidebarRegion, MapView) {
    var BrowseButtonView, NavigationHeaderView, NavigationLayout, SearchLayoutView, UnitListLayoutView;
    SearchLayoutView = _arg.SearchLayoutView, UnitListLayoutView = _arg.UnitListLayoutView;
    NavigationLayout = (function(_super) {
      __extends(NavigationLayout, _super);

      function NavigationLayout() {
        this.setMaxHeight = __bind(this.setMaxHeight, this);
        this.updateMaxHeights = __bind(this.updateMaxHeights, this);
        return NavigationLayout.__super__.constructor.apply(this, arguments);
      }

      NavigationLayout.prototype.className = 'service-sidebar';

      NavigationLayout.prototype.template = 'navigation-layout';

      NavigationLayout.prototype.regionType = SidebarRegion;

      NavigationLayout.prototype.regions = {
        header: '#navigation-header',
        contents: '#navigation-contents'
      };

      NavigationLayout.prototype.onShow = function() {
        return this.header.show(new NavigationHeaderView({
          layout: this,
          searchState: this.searchState,
          searchResults: this.searchResults,
          selectedUnits: this.selectedUnits
        }));
      };

      NavigationLayout.prototype.initialize = function(options) {
        this.serviceTreeCollection = options.serviceTreeCollection;
        this.selectedServices = options.selectedServices;
        this.searchResults = options.searchResults;
        this.selectedUnits = options.selectedUnits;
        this.units = options.units;
        this.selectedEvents = options.selectedEvents;
        this.selectedPosition = options.selectedPosition;
        this.searchState = options.searchState;
        this.routingParameters = options.routingParameters;
        this.route = options.route;
        this.breadcrumbs = [];
        this.openViewType = null;
        return this.addListeners();
      };

      NavigationLayout.prototype.addListeners = function() {
        this.listenTo(this.searchResults, 'ready', function() {
          return this.change('search');
        });
        this.listenTo(this.serviceTreeCollection, 'finished', function() {
          this.openViewType = null;
          return this.change('browse');
        });
        this.listenTo(this.selectedServices, 'reset', function(coll, opts) {
          if (!(opts != null ? opts.skip_navigate : void 0)) {
            return this.change('browse');
          }
        });
        this.listenTo(this.selectedPosition, 'change:value', function(w, value) {
          var previous;
          previous = this.selectedPosition.previous('value');
          if (previous != null) {
            this.stopListening(previous);
          }
          if (value != null) {
            this.listenTo(value, 'change:radiusFilter', this.radiusFilterChanged);
          }
          if (this.selectedPosition.isSet()) {
            return this.change('position');
          } else if (this.openViewType === 'position') {
            return this.closeContents();
          }
        });
        this.listenTo(this.selectedServices, 'add', function(service) {
          this.closeContents();
          this.service = service;
          return this.listenTo(this.service.get('units'), 'finished', (function(_this) {
            return function() {
              return _this.change('service-units');
            };
          })(this));
        });
        this.listenTo(this.selectedServices, 'remove', (function(_this) {
          return function(service, coll) {
            if (coll.isEmpty()) {
              if (_this.openViewType === 'service-units') {
                return _this.closeContents();
              }
            } else {
              return _this.change('service-units');
            }
          };
        })(this));
        this.listenTo(this.selectedUnits, 'reset', function(unit, coll, opts) {
          var currentViewType, _ref;
          currentViewType = (_ref = this.contents.currentView) != null ? _ref.type : void 0;
          if (currentViewType === 'details') {
            if (this.searchResults.isEmpty() && this.selectedUnits.isEmpty()) {
              this.closeContents();
            }
          }
          if (!this.selectedUnits.isEmpty()) {
            return this.change('details');
          }
        });
        this.listenTo(this.selectedUnits, 'remove', function(unit, coll, opts) {
          return this.change(null);
        });
        this.listenTo(this.selectedEvents, 'reset', function(unit, coll, opts) {
          if (!this.selectedEvents.isEmpty()) {
            return this.change('event');
          }
        });
        this.contents.on('show', this.updateMaxHeights);
        $(window).resize(this.updateMaxHeights);
        return this.listenTo(app.vent, 'landing-page-cleared', this.setMaxHeight);
      };

      NavigationLayout.prototype.updateMaxHeights = function() {
        var currentViewType, _ref;
        this.setMaxHeight();
        currentViewType = (_ref = this.contents.currentView) != null ? _ref.type : void 0;
        return MapView.setMapActiveAreaMaxHeight({
          maximize: !currentViewType || currentViewType === 'search'
        });
      };

      NavigationLayout.prototype.setMaxHeight = function() {
        var $limitedElement, maxHeight;
        $limitedElement = this.$el.find('.limit-max-height');
        if (!$limitedElement.length) {
          return;
        }
        maxHeight = $(window).innerHeight() - $limitedElement.offset().top;
        $limitedElement.css({
          'max-height': maxHeight
        });
        return this.$el.find('.map-active-area').css('padding-bottom', MapView.mapActiveAreaMaxHeight());
      };

      NavigationLayout.prototype.getAnimationType = function(newViewType) {
        var currentViewType, _ref;
        currentViewType = (_ref = this.contents.currentView) != null ? _ref.type : void 0;
        if (currentViewType) {
          switch (currentViewType) {
            case 'event':
              return 'right';
            case 'details':
              switch (newViewType) {
                case 'event':
                  return 'left';
                case 'details':
                  return 'up-and-down';
                default:
                  return 'right';
              }
              break;
            case 'service-tree':
              return this.contents.currentView.animationType || 'left';
          }
        }
        return null;
      };

      NavigationLayout.prototype.closeContents = function() {
        this.change(null);
        this.openViewType = null;
        this.header.currentView.updateClasses(null);
        return MapView.setMapActiveAreaMaxHeight({
          maximize: true
        });
      };

      NavigationLayout.prototype.radiusFilterChanged = function(value) {
        if (value.get('radiusFilter') > 0) {
          return this.listenToOnce(this.units, 'finished', (function(_this) {
            return function() {
              return _this.change('radius');
            };
          })(this));
        }
      };

      NavigationLayout.prototype.change = function(type) {
        var view;
        if (type === 'browse' && this.openViewType === 'browse') {
          return;
        }
        switch (type) {
          case 'browse':
            view = new ServiceTreeView({
              collection: this.serviceTreeCollection,
              selectedServices: this.selectedServices,
              breadcrumbs: this.breadcrumbs
            });
            break;
          case 'radius':
            view = new UnitListLayoutView({
              fullCollection: this.units,
              collectionType: 'radius',
              position: this.selectedPosition.value(),
              resultType: 'unit',
              onlyResultType: true
            });
            break;
          case 'search':
            view = new SearchLayoutView({
              collection: this.searchResults
            });
            break;
          case 'service-units':
            view = new UnitListLayoutView({
              fullCollection: this.units,
              collectionType: 'service',
              resultType: 'unit',
              onlyResultType: true
            });
            break;
          case 'details':
            view = new UnitDetailsView({
              model: this.selectedUnits.first(),
              route: this.route,
              parent: this,
              routingParameters: this.routingParameters,
              searchResults: this.searchResults,
              selectedUnits: this.selectedUnits,
              selectedPosition: this.selectedPosition
            });
            break;
          case 'event':
            view = new EventDetailsView({
              model: this.selectedEvents.first()
            });
            break;
          case 'position':
            view = new PositionDetailsView({
              model: this.selectedPosition.value(),
              route: this.route,
              selectedPosition: this.selectedPosition,
              routingParameters: this.routingParameters
            });
            break;
          default:
            this.opened = false;
            view = null;
            this.contents.reset();
        }
        this.updatePersonalisationButtonClass(type);
        if (view != null) {
          this.contents.show(view, {
            animationType: this.getAnimationType(type)
          });
          this.openViewType = type;
          this.opened = true;
          this.listenToOnce(view, 'user:close', (function(_this) {
            return function(ev) {
              if (type === 'details') {
                if (!_this.selectedServices.isEmpty()) {
                  return _this.change('service-units');
                } else if ('distance' in _this.units.filters) {
                  return _this.change('radius');
                }
              }
            };
          })(this));
        }
        if (type !== 'details') {
          return app.vent.trigger('site-title:change', null);
        }
      };

      NavigationLayout.prototype.updatePersonalisationButtonClass = function(type) {
        if (type === 'browse' || type === 'search' || type === 'details' || type === 'event' || type === 'position') {
          return $('#personalisation').addClass('hidden');
        } else {
          return $('#personalisation').removeClass('hidden');
        }
      };

      return NavigationLayout;

    })(base.SMLayout);
    NavigationHeaderView = (function(_super) {
      __extends(NavigationHeaderView, _super);

      function NavigationHeaderView() {
        return NavigationHeaderView.__super__.constructor.apply(this, arguments);
      }

      NavigationHeaderView.prototype.className = 'container';

      NavigationHeaderView.prototype.template = 'navigation-header';

      NavigationHeaderView.prototype.regions = {
        search: '#search-region',
        browse: '#browse-region'
      };

      NavigationHeaderView.prototype.events = {
        'click .header': 'open',
        'keypress .header': 'toggleOnKeypress',
        'click .action-button.close-button': 'close'
      };

      NavigationHeaderView.prototype.initialize = function(options) {
        this.navigationLayout = options.layout;
        this.searchState = options.searchState;
        this.searchResults = options.searchResults;
        return this.selectedUnits = options.selectedUnits;
      };

      NavigationHeaderView.prototype.onShow = function() {
        var searchInputView;
        searchInputView = new SearchInputView(this.searchState, this.searchResults);
        this.search.show(searchInputView);
        this.listenTo(searchInputView, 'open', (function(_this) {
          return function() {
            _this.updateClasses('search');
            return _this.navigationLayout.updatePersonalisationButtonClass('search');
          };
        })(this));
        return this.browse.show(new BrowseButtonView());
      };

      NavigationHeaderView.prototype._open = function(actionType) {
        this.updateClasses(actionType);
        return this.navigationLayout.change(actionType);
      };

      NavigationHeaderView.prototype.open = function(event) {
        return this._open($(event.currentTarget).data('type'));
      };

      NavigationHeaderView.prototype.toggleOnKeypress = function(event) {
        var isNavigationVisible, target;
        target = $(event.currentTarget).data('type');
        isNavigationVisible = !!$('#navigation-contents').children().length;
        if (event.keyCode !== 13) {
          return;
        }
        if (isNavigationVisible) {
          return this._close(target);
        } else {
          return this._open(target);
        }
      };

      NavigationHeaderView.prototype._close = function(headerType) {
        this.updateClasses(null);
        if (headerType === 'search') {
          this.$el.find('input').val('');
          app.commands.execute('closeSearch');
        }
        if (headerType === 'search' && !this.selectedUnits.isEmpty()) {
          return;
        }
        return this.navigationLayout.closeContents();
      };

      NavigationHeaderView.prototype.close = function(event) {
        var headerType;
        event.preventDefault();
        event.stopPropagation();
        if (!$(event.currentTarget).hasClass('close-button')) {
          return false;
        }
        headerType = $(event.target).closest('.header').data('type');
        return this._close(headerType);
      };

      NavigationHeaderView.prototype.updateClasses = function(opening) {
        var classname;
        classname = "" + opening + "-open";
        if (this.$el.hasClass(classname)) {
          return;
        }
        this.$el.removeClass().addClass('container');
        if (opening != null) {
          return this.$el.addClass(classname);
        }
      };

      return NavigationHeaderView;

    })(base.SMLayout);
    BrowseButtonView = (function(_super) {
      __extends(BrowseButtonView, _super);

      function BrowseButtonView() {
        return BrowseButtonView.__super__.constructor.apply(this, arguments);
      }

      BrowseButtonView.prototype.template = 'navigation-browse';

      return BrowseButtonView;

    })(base.SMItemView);
    return NavigationLayout;
  });

}).call(this);

//# sourceMappingURL=navigation.js.map
