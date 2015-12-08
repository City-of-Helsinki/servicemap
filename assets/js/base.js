(function() {
  var __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function() {
    return {
      mixOf: function() {
        var Mixed, base, mixins;
        base = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return Mixed = (function(_super) {
          var method, mixin, name, _i, _ref;

          __extends(Mixed, _super);

          function Mixed() {
            return Mixed.__super__.constructor.apply(this, arguments);
          }

          for (_i = mixins.length - 1; _i >= 0; _i += -1) {
            mixin = mixins[_i];
            _ref = mixin.prototype;
            for (name in _ref) {
              method = _ref[name];
              Mixed.prototype[name] = method;
            }
          }

          Mixed;

          return Mixed;

        })(base);
      },
      resolveImmediately: function() {
        return $.Deferred().resolve().promise();
      },
      withDeferred: function(callback) {
        var deferred;
        deferred = $.Deferred();
        callback(deferred);
        return deferred.promise();
      },
      pad: function(number) {
        var pad, str;
        str = "" + number;
        pad = "00000";
        return pad.substring(0, pad.length - str.length) + str;
      }
    };
  });

}).call(this);

//# sourceMappingURL=base.js.map
