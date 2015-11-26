(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base'], function(base) {
    var LocationRefreshButtonView;
    return LocationRefreshButtonView = (function(_super) {
      __extends(LocationRefreshButtonView, _super);

      function LocationRefreshButtonView() {
        return LocationRefreshButtonView.__super__.constructor.apply(this, arguments);
      }

      LocationRefreshButtonView.prototype.template = 'location-refresh-button';

      LocationRefreshButtonView.prototype.events = {
        'click': 'resetPosition'
      };

      LocationRefreshButtonView.prototype.resetPosition = function(ev) {
        ev.stopPropagation();
        ev.preventDefault();
        return app.commands.execute('resetPosition');
      };

      LocationRefreshButtonView.prototype.render = function() {
        LocationRefreshButtonView.__super__.render.call(this);
        return this.el;
      };

      return LocationRefreshButtonView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=location-refresh-button.js.map
