(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(['cs!app/views/base', 'backbone'], function(baseviews, Backbone) {
    var EmbeddedMap, TitleBarView;
    EmbeddedMap = (function(_super) {
      __extends(EmbeddedMap, _super);

      function EmbeddedMap() {
        return EmbeddedMap.__super__.constructor.apply(this, arguments);
      }

      EmbeddedMap.prototype.initialize = function(options) {
        this.mapView = options.mapView;
        this.listenTo(app.vent, 'unit:render-one', this.renderUnit);
        this.listenTo(app.vent, 'units:render-with-filter', this.renderUnitsWithFilter);
        return this.listenTo(app.vent, 'units:render-category', this.renderUnitsByCategory);
      };

      EmbeddedMap.prototype.renderUnitsByCategory = function(isSelected) {
        var onlyCategories, privateCategories, privateUnits, publicCategories, publicUnits, unitsInCategory;
        publicCategories = [100, 101, 102, 103, 104];
        privateCategories = [105];
        onlyCategories = function(categoriesArray) {
          return function(model) {
            return _.contains(categoriesArray, model.get('provider_type'));
          };
        };
        publicUnits = this.unitList.filter(onlyCategories(publicCategories));
        privateUnits = this.unitList.filter(onlyCategories(privateCategories));
        unitsInCategory = [];
        if (!isSelected["public"]) {
          _.extend(unitsInCategory, publicUnits);
        }
        if (!isSelected["private"]) {
          _.extend(unitsInCategory, privateUnits);
        }
        return this.mapView.drawUnits(new models.UnitList(unitsInCategory));
      };

      EmbeddedMap.prototype.fetchAdministrativeDivisions = function(params, callback) {
        var divisions;
        divisions = new models.AdministrativeDivisionList();
        return divisions.fetch({
          data: {
            ocd_id: params
          },
          success: callback
        });
      };

      EmbeddedMap.prototype.findUniqueAdministrativeDivisions = function(collection) {
        var byName, divisionNames, divisionNamesPartials;
        byName = function(divisionModel) {
          return divisionModel.toJSON().name;
        };
        divisionNames = collection.chain().map(byName).compact().unique().value();
        divisionNamesPartials = {};
        if (divisionNames.length > 1) {
          divisionNamesPartials.start = _.initial(divisionNames).join(', ');
          divisionNamesPartials.end = _.last(divisionNames);
        } else {
          divisionNamesPartials.start = divisionNames[0];
        }
        return app.vent.trigger('administration-divisions-fetched', divisionNamesPartials);
      };

      return EmbeddedMap;

    })(Backbone.View);
    TitleBarView = (function(_super) {
      __extends(TitleBarView, _super);

      function TitleBarView() {
        this.divisionNames = __bind(this.divisionNames, this);
        return TitleBarView.__super__.constructor.apply(this, arguments);
      }

      TitleBarView.prototype.template = 'embedded-title-bar';

      TitleBarView.prototype.className = 'panel panel-default';

      TitleBarView.prototype.events = {
        'click a': 'preventDefault',
        'click .show-button': 'toggleShow',
        'click .panel-heading': 'collapseCategoryMenu'
      };

      TitleBarView.prototype.initialize = function(model) {
        this.model = model;
        return this.listenTo(this.model, 'sync', this.render);
      };

      TitleBarView.prototype.divisionNames = function(divisions) {
        return divisions.pluck('name');
      };

      TitleBarView.prototype.serializeData = function() {
        return {
          divisions: this.divisionNames(this.model)
        };
      };

      TitleBarView.prototype.show = function() {
        this.delegateEvents;
        return this.$el.removeClass('hide');
      };

      TitleBarView.prototype.hide = function() {
        this.undelegateEvents();
        return this.$el.addClass('hide');
      };

      TitleBarView.prototype.preventDefault = function(ev) {
        return ev.preventDefault();
      };

      TitleBarView.prototype.toggleShow = function(ev) {
        var isSelected, privateToggle, publicToggle, target;
        publicToggle = this.$('.public');
        privateToggle = this.$('.private');
        target = $(ev.target);
        target.toggleClass('selected');
        isSelected = {
          "public": publicToggle.hasClass('selected'),
          "private": privateToggle.hasClass('selected')
        };
        return app.vent.trigger('units:render-category', isSelected);
      };

      TitleBarView.prototype.collapseCategoryMenu = function() {
        return $('.panel-heading').toggleClass('open');
      };

      return TitleBarView;

    })(baseviews.SMItemView);
    return TitleBarView;
  });

}).call(this);

//# sourceMappingURL=embedded-views.js.map
