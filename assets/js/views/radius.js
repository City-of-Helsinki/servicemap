(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base'], function(base) {
    var RadiusControlsView;
    return RadiusControlsView = (function(_super) {
      __extends(RadiusControlsView, _super);

      function RadiusControlsView() {
        return RadiusControlsView.__super__.constructor.apply(this, arguments);
      }

      RadiusControlsView.prototype.template = 'radius-controls';

      RadiusControlsView.prototype.className = 'radius-controls';

      RadiusControlsView.prototype.events = {
        'change': 'onChange'
      };

      RadiusControlsView.prototype.serializeData = function() {
        return {
          selected: this.selected || 750,
          values: [250, 500, 750, 1000, 2000, 3000, 4000]
        };
      };

      RadiusControlsView.prototype.initialize = function(_arg) {
        this.selected = _arg.radius;
      };

      RadiusControlsView.prototype.onChange = function(ev) {
        this.selected = $(ev.target).val();
        this.render();
        return app.commands.execute('setRadiusFilter', this.selected);
      };

      return RadiusControlsView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=radius.js.map
