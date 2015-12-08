(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'cs!app/p13n', 'cs!app/views/base'], function(_, p13n, base) {
    var ServiceCartView;
    return ServiceCartView = (function(_super) {
      __extends(ServiceCartView, _super);

      function ServiceCartView() {
        return ServiceCartView.__super__.constructor.apply(this, arguments);
      }

      ServiceCartView.prototype.template = 'service-cart';

      ServiceCartView.prototype.tagName = 'ul';

      ServiceCartView.prototype.className = 'expanded container main-list';

      ServiceCartView.prototype.events = function() {
        return {
          'click .personalisation-container .maximizer': 'maximize',
          'keydown .personalisation-container .maximizer': this.keyboardHandler(this.maximize, ['space', 'enter']),
          'click .button.cart-close-button': 'minimize',
          'click .button.close-button': 'closeService',
          'keydown .button.close-button': this.keyboardHandler(this.closeService, ['space', 'enter']),
          'click input': 'selectLayerInput',
          'click label': 'selectLayerLabel'
        };
      };

      ServiceCartView.prototype.initialize = function(opts) {
        this.collection = opts.collection;
        this.listenTo(this.collection, 'add', this.maximize);
        this.listenTo(this.collection, 'remove', (function(_this) {
          return function() {
            if (_this.collection.length) {
              return _this.render();
            } else {
              return _this.minimize();
            }
          };
        })(this));
        this.listenTo(this.collection, 'reset', this.render);
        this.listenTo(this.collection, 'minmax', this.render);
        this.listenTo(p13n, 'change', (function(_this) {
          return function(path, value) {
            if (path[0] === 'map_background_layer') {
              return _this.render();
            }
          };
        })(this));
        if (this.collection.length) {
          return this.minimized = false;
        } else {
          return this.minimized = true;
        }
      };

      ServiceCartView.prototype.maximize = function() {
        this.minimized = false;
        return this.collection.trigger('minmax');
      };

      ServiceCartView.prototype.minimize = function() {
        this.minimized = true;
        return this.collection.trigger('minmax');
      };

      ServiceCartView.prototype.onRender = function() {
        if (this.minimized) {
          this.$el.removeClass('expanded');
          return this.$el.addClass('minimized');
        } else {
          this.$el.addClass('expanded');
          this.$el.removeClass('minimized');
          return _.defer((function(_this) {
            return function() {
              return _this.$el.find('input:checked').first().focus();
            };
          })(this));
        }
      };

      ServiceCartView.prototype.serializeData = function() {
        var data;
        if (this.minimized) {
          return {
            minimized: true
          };
        }
        data = ServiceCartView.__super__.serializeData.call(this);
        data.layers = p13n.getMapBackgroundLayers();
        return data;
      };

      ServiceCartView.prototype.closeService = function(ev) {
        return app.commands.execute('removeService', $(ev.currentTarget).data('service'));
      };

      ServiceCartView.prototype._selectLayer = function(value) {
        return p13n.setMapBackgroundLayer(value);
      };

      ServiceCartView.prototype.selectLayerInput = function(ev) {
        return this._selectLayer($(ev.currentTarget).attr('value'));
      };

      ServiceCartView.prototype.selectLayerLabel = function(ev) {
        return this._selectLayer($(ev.currentTarget).data('layer'));
      };

      return ServiceCartView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=service-cart.js.map
