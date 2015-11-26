(function() {
  define(function() {
    var ColorMatcher;
    ColorMatcher = (function() {
      ColorMatcher.serviceColors = {
        50000: [77, 139, 0],
        50001: [192, 79, 220],
        50002: [252, 173, 0],
        50003: [154, 0, 0],
        26412: [0, 81, 142],
        27918: [67, 48, 64],
        27718: [60, 210, 0],
        25000: [142, 139, 255],
        26190: [240, 66, 0]
      };

      function ColorMatcher(selectedServices) {
        this.selectedServices = selectedServices;
      }

      ColorMatcher.rgb = function(r, g, b) {
        return "rgb(" + r + ", " + g + ", " + b + ")";
      };

      ColorMatcher.rgba = function(r, g, b, a) {
        return "rgba(" + r + ", " + g + ", " + b + ", " + a + ")";
      };

      ColorMatcher.prototype.serviceColor = function(service) {
        return this.serviceRootIdColor(service.get('root'));
      };

      ColorMatcher.prototype.serviceRootIdColor = function(id) {
        var b, g, r, _ref;
        _ref = this.constructor.serviceColors[id], r = _ref[0], g = _ref[1], b = _ref[2];
        return this.constructor.rgb(r, g, b);
      };

      ColorMatcher.prototype.unitColor = function(unit) {
        var b, g, r, rootService, roots, _ref;
        roots = unit.get('root_services');
        if (this.selectedServices != null) {
          rootService = _.find(roots, (function(_this) {
            return function(rid) {
              return _this.selectedServices.find(function(s) {
                return s.get('root') === rid;
              });
            };
          })(this));
        }
        if (rootService == null) {
          rootService = roots[0];
        }
        _ref = this.constructor.serviceColors[rootService], r = _ref[0], g = _ref[1], b = _ref[2];
        return this.constructor.rgb(r, g, b);
      };

      return ColorMatcher;

    })();
    return ColorMatcher;
  });

}).call(this);

//# sourceMappingURL=color.js.map
