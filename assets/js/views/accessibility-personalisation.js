(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base'], function(base) {
    var AccessibilityPersonalisationView;
    return AccessibilityPersonalisationView = (function(_super) {
      __extends(AccessibilityPersonalisationView, _super);

      function AccessibilityPersonalisationView() {
        return AccessibilityPersonalisationView.__super__.constructor.apply(this, arguments);
      }

      AccessibilityPersonalisationView.prototype.className = 'accessibility-personalisation';

      AccessibilityPersonalisationView.prototype.template = 'accessibility-personalisation';

      AccessibilityPersonalisationView.prototype.initialize = function(activeModes) {
        this.activeModes = activeModes;
      };

      AccessibilityPersonalisationView.prototype.serializeData = function() {
        return {
          accessibility_viewpoints: this.activeModes
        };
      };

      return AccessibilityPersonalisationView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=accessibility-personalisation.js.map
