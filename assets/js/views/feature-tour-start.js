(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base', 'cs!app/tour'], function(base, tour) {
    var TourStartButton;
    return TourStartButton = (function(_super) {
      __extends(TourStartButton, _super);

      function TourStartButton() {
        return TourStartButton.__super__.constructor.apply(this, arguments);
      }

      TourStartButton.prototype.className = 'feature-tour-start';

      TourStartButton.prototype.template = 'feature-tour-start';

      TourStartButton.prototype.events = {
        'click .close-button': 'hideTour',
        'click .prompt-button': 'showTour'
      };

      TourStartButton.prototype.hideTour = function(ev) {
        p13n.set('hide_tour', true);
        this.trigger('close');
        return ev.stopPropagation();
      };

      TourStartButton.prototype.showTour = function(ev) {
        tour.startTour();
        return this.trigger('close');
      };

      return TourStartButton;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=feature-tour-start.js.map
