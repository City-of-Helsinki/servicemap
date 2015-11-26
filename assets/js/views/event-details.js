(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/dateformat', 'cs!app/views/base'], function(dateformat, base) {
    var EventDetailsView;
    return EventDetailsView = (function(_super) {
      __extends(EventDetailsView, _super);

      function EventDetailsView() {
        return EventDetailsView.__super__.constructor.apply(this, arguments);
      }

      EventDetailsView.prototype.id = 'event-view-container';

      EventDetailsView.prototype.className = 'navigation-element';

      EventDetailsView.prototype.template = 'event';

      EventDetailsView.prototype.events = {
        'click .back-button': 'goBack',
        'click .sp-name a': 'goBack'
      };

      EventDetailsView.prototype.type = 'event';

      EventDetailsView.prototype.initialize = function(options) {
        this.embedded = options.embedded;
        return this.servicePoint = this.model.get('unit');
      };

      EventDetailsView.prototype.serializeData = function() {
        var data, endTime, startTime;
        data = this.model.toJSON();
        data.embedded_mode = this.embedded;
        startTime = this.model.get('start_time');
        endTime = this.model.get('end_time');
        data.datetime = dateformat.humanizeEventDatetime(startTime, endTime, 'large');
        if (this.servicePoint != null) {
          data.sp_name = this.servicePoint.get('name');
          data.sp_url = this.servicePoint.get('www_url');
          data.sp_phone = this.servicePoint.get('phone');
        } else {
          data.sp_name = this.model.get('location_extra_info');
          data.prevent_back = true;
        }
        return data;
      };

      EventDetailsView.prototype.goBack = function(event) {
        event.preventDefault();
        app.commands.execute('clearSelectedEvent');
        return app.commands.execute('selectUnit', this.servicePoint);
      };

      return EventDetailsView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=event-details.js.map
