(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['i18next', 'cs!app/views/base'], function(_arg, _arg1) {
    var SMItemView, ServiceMapDisclaimersOverlayView, ServiceMapDisclaimersView, t;
    t = _arg.t;
    SMItemView = _arg1.SMItemView;
    return {
      ServiceMapDisclaimersView: ServiceMapDisclaimersView = (function(_super) {
        __extends(ServiceMapDisclaimersView, _super);

        function ServiceMapDisclaimersView() {
          return ServiceMapDisclaimersView.__super__.constructor.apply(this, arguments);
        }

        ServiceMapDisclaimersView.prototype.template = 'description-of-service';

        ServiceMapDisclaimersView.prototype.className = 'content modal-dialog about';

        ServiceMapDisclaimersView.prototype.serializeData = function() {
          return {
            lang: p13n.getLanguage()
          };
        };

        return ServiceMapDisclaimersView;

      })(SMItemView),
      ServiceMapDisclaimersOverlayView: ServiceMapDisclaimersOverlayView = (function(_super) {
        __extends(ServiceMapDisclaimersOverlayView, _super);

        function ServiceMapDisclaimersOverlayView() {
          return ServiceMapDisclaimersOverlayView.__super__.constructor.apply(this, arguments);
        }

        ServiceMapDisclaimersOverlayView.prototype.template = 'disclaimers-overlay';

        ServiceMapDisclaimersOverlayView.prototype.serializeData = function() {
          var copyrightLink, layer;
          layer = p13n.get('map_background_layer');
          if (layer === 'servicemap' || layer === 'accessible_map') {
            copyrightLink = "https://www.openstreetmap.org/copyright";
          }
          return {
            copyright: t("disclaimer.copyright." + layer),
            copyrightLink: copyrightLink
          };
        };

        ServiceMapDisclaimersOverlayView.prototype.events = {
          'click #about-the-service': 'onAboutClick'
        };

        ServiceMapDisclaimersOverlayView.prototype.onAboutClick = function(ev) {
          return app.commands.execute('showServiceMapDescription');
        };

        return ServiceMapDisclaimersOverlayView;

      })(SMItemView)
    };
  });

}).call(this);

//# sourceMappingURL=service-map-disclaimers.js.map
