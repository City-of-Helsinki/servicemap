(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['underscore', 'cs!app/models', 'cs!app/map-view', 'cs!app/views/base', 'cs!app/views/route'], function(_, models, MapView, base, RouteView) {
    var DivisionListItemView, DivisionListView, PositionDetailsView, UnitListItemView, UnitListView;
    PositionDetailsView = (function(_super) {
      __extends(PositionDetailsView, _super);

      function PositionDetailsView() {
        return PositionDetailsView.__super__.constructor.apply(this, arguments);
      }

      PositionDetailsView.prototype.type = 'position';

      PositionDetailsView.prototype.id = 'details-view-container';

      PositionDetailsView.prototype.className = 'navigation-element limit-max-height';

      PositionDetailsView.prototype.template = 'position';

      PositionDetailsView.prototype.regions = {
        'areaServices': '.area-services-placeholder',
        'adminDivisions': '.admin-div-placeholder',
        'routeRegion': '.section.route-section'
      };

      PositionDetailsView.prototype.events = {
        'click .map-active-area': 'showMap',
        'click .mobile-header': 'showContent',
        'click .icon-icon-close': 'selfDestruct',
        'click #reset-location': 'resetLocation',
        'click #add-circle': 'addCircle'
      };

      PositionDetailsView.prototype.initialize = function(options) {
        this.selectedPosition = options.selectedPosition;
        this.route = options.route;
        this.parent = options.parent;
        this.routingParameters = options.routingParameters;
        this.sortedDivisions = ['postcode_area', 'neighborhood', 'rescue_district', 'health_station_district', 'maternity_clinic_district', 'income_support_district', 'lower_comprehensive_school_district_fi', 'lower_comprehensive_school_district_sv', 'upper_comprehensive_school_district_fi', 'upper_comprehensive_school_district_sv'];
        this.divList = new models.AdministrativeDivisionList();
        this.listenTo(this.model, 'reverse-geocode', (function(_this) {
          return function() {
            return _this.fetchDivisions().done(function() {
              return _this.render();
            });
          };
        })(this));
        this.divList.comparator = (function(_this) {
          return function(a, b) {
            var indexA, indexB;
            indexA = _.indexOf(_this.sortedDivisions, a.get('type'));
            indexB = _.indexOf(_this.sortedDivisions, b.get('type'));
            if (indexA < indexB) {
              return -1;
            }
            if (indexB < indexA) {
              return 1;
            }
            return 0;
          };
        })(this);
        this.listenTo(this.divList, 'reset', this.renderAdminDivs);
        return this.fetchDivisions().done((function(_this) {
          return function() {
            return _this.render();
          };
        })(this));
      };

      PositionDetailsView.prototype.fetchDivisions = function() {
        var coords;
        coords = this.model.get('location').coordinates;
        return this.divList.fetch({
          data: {
            lon: coords[0],
            lat: coords[1],
            unit_include: 'name,root_services,location',
            type: (_.union(this.sortedDivisions, ['emergency_care_district'])).join(','),
            geometry: 'true'
          },
          reset: true
        });
      };

      PositionDetailsView.prototype.serializeData = function() {
        var data;
        data = PositionDetailsView.__super__.serializeData.call(this);
        data.icon_class = (function() {
          switch (this.model.origin()) {
            case 'address':
              return 'icon-icon-address';
            case 'detected':
              return 'icon-icon-you-are-here';
            case 'clicked':
              return 'icon-icon-address';
          }
        }).call(this);
        data.origin = this.model.origin();
        data.neighborhood = this.divList.findWhere({
          type: 'neighborhood'
        });
        data.name = this.model.humanAddress();
        return data;
      };

      PositionDetailsView.prototype.resetLocation = function() {
        return app.commands.execute('resetPosition', this.model);
      };

      PositionDetailsView.prototype.addCircle = function() {
        return app.commands.execute('setRadiusFilter', 750);
      };

      PositionDetailsView.prototype.onRender = function() {
        this.renderAdminDivs();
        return this.routeRegion.show(new RouteView({
          model: this.model,
          route: this.route,
          parentView: this,
          routingParameters: this.routingParameters,
          selectedUnits: null,
          selectedPosition: this.selectedPosition
        }));
      };

      PositionDetailsView.prototype.renderAdminDivs = function() {
        var divsWithUnits, emergencyDiv, units;
        divsWithUnits = this.divList.filter(function(x) {
          return x.has('unit');
        });
        emergencyDiv = this.divList.find(function(x) {
          return x.get('type') === 'emergency_care_district';
        });
        if (divsWithUnits.length > 0) {
          units = new models.UnitList(divsWithUnits.map(function(x) {
            var unit;
            unit = new models.Unit(x.get('unit'));
            unit.set('area', x);
            if (x.get('type') === 'health_station_district') {
              unit.set('emergencyUnitId', emergencyDiv.getEmergencyCareUnit());
            }
            return unit;
          }));
          this.areaServices.show(new UnitListView({
            collection: units
          }));
          return this.adminDivisions.show(new DivisionListView({
            collection: new models.AdministrativeDivisionList(this.divList.filter((function(_this) {
              return function(x) {
                return x.get('type') !== 'emergency_care_district';
              };
            })(this)))
          }));
        }
      };

      PositionDetailsView.prototype.showMap = function(event) {
        event.preventDefault();
        this.$el.addClass('minimized');
        return MapView.setMapActiveAreaMaxHeight({
          maximize: true
        });
      };

      PositionDetailsView.prototype.showContent = function(event) {
        event.preventDefault();
        this.$el.removeClass('minimized');
        return MapView.setMapActiveAreaMaxHeight({
          maximize: false
        });
      };

      PositionDetailsView.prototype.selfDestruct = function(event) {
        event.stopPropagation();
        return app.commands.execute('clearSelectedPosition');
      };

      return PositionDetailsView;

    })(base.SMLayout);
    DivisionListItemView = (function(_super) {
      __extends(DivisionListItemView, _super);

      function DivisionListItemView() {
        this.initialize = __bind(this.initialize, this);
        this.handleClick = __bind(this.handleClick, this);
        return DivisionListItemView.__super__.constructor.apply(this, arguments);
      }

      DivisionListItemView.prototype.events = {
        'click': 'handleClick'
      };

      DivisionListItemView.prototype.tagName = 'li';

      DivisionListItemView.prototype.template = 'division-list-item';

      DivisionListItemView.prototype.handleClick = function() {
        return app.commands.execute('toggleDivision', this.model);
      };

      DivisionListItemView.prototype.initialize = function() {
        return this.listenTo(this.model, 'change:selected', this.render);
      };

      return DivisionListItemView;

    })(base.SMItemView);
    DivisionListView = (function(_super) {
      __extends(DivisionListView, _super);

      function DivisionListView() {
        return DivisionListView.__super__.constructor.apply(this, arguments);
      }

      DivisionListView.prototype.tagName = 'ul';

      DivisionListView.prototype.className = 'division-list sublist';

      DivisionListView.prototype.itemView = DivisionListItemView;

      return DivisionListView;

    })(base.SMCollectionView);
    UnitListItemView = (function(_super) {
      __extends(UnitListItemView, _super);

      function UnitListItemView() {
        this.handleClick = __bind(this.handleClick, this);
        this.handleInnerClick = __bind(this.handleInnerClick, this);
        return UnitListItemView.__super__.constructor.apply(this, arguments);
      }

      UnitListItemView.prototype.events = {
        'click a': 'handleInnerClick',
        'click': 'handleClick'
      };

      UnitListItemView.prototype.tagName = 'li';

      UnitListItemView.prototype.template = 'unit-list-item';

      UnitListItemView.prototype.serializeData = function() {
        var data;
        data = UnitListItemView.__super__.serializeData.call(this);
        return data;
      };

      UnitListItemView.prototype.handleInnerClick = function(ev) {
        return ev != null ? ev.stopPropagation() : void 0;
      };

      UnitListItemView.prototype.handleClick = function(ev) {
        if (ev != null) {
          ev.preventDefault();
        }
        app.commands.execute('setUnit', this.model);
        return app.commands.execute('selectUnit', this.model);
      };

      return UnitListItemView;

    })(base.SMItemView);
    UnitListView = (function(_super) {
      __extends(UnitListView, _super);

      function UnitListView() {
        return UnitListView.__super__.constructor.apply(this, arguments);
      }

      UnitListView.prototype.tagName = 'ul';

      UnitListView.prototype.className = 'unit-list sublist';

      UnitListView.prototype.itemView = UnitListItemView;

      return UnitListView;

    })(base.SMCollectionView);
    return PositionDetailsView;
  });

}).call(this);

//# sourceMappingURL=position-details.js.map
