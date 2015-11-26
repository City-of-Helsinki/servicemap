(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base'], function(base) {
    var FeedbackConfirmationView;
    return FeedbackConfirmationView = (function(_super) {
      __extends(FeedbackConfirmationView, _super);

      function FeedbackConfirmationView() {
        return FeedbackConfirmationView.__super__.constructor.apply(this, arguments);
      }

      FeedbackConfirmationView.prototype.template = 'feedback-confirmation';

      FeedbackConfirmationView.prototype.className = 'content modal-dialog';

      FeedbackConfirmationView.prototype.events = {
        'click .ok-button': '_close'
      };

      FeedbackConfirmationView.prototype.initialize = function(unit) {
        this.unit = unit;
      };

      FeedbackConfirmationView.prototype.serializeData = function() {
        return {
          unit: this.unit.toJSON()
        };
      };

      FeedbackConfirmationView.prototype._close = function() {
        return app.commands.execute('closeFeedback');
      };

      return FeedbackConfirmationView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=feedback-confirmation.js.map
