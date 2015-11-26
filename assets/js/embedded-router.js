(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/models', 'cs!app/spinner', 'cs!app/embedded-views', 'backbone.marionette', 'jquery'], function(models, Spinner, TitleBarView, Marionette, $) {
    var PAGE_SIZE, Router, delayTime, spinner;
    PAGE_SIZE = 1000;
    delayTime = 1000;
    spinner = new Spinner({
      container: document.body
    });
    Router = (function(_super) {
      __extends(Router, _super);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.execute = function(callback, args) {
        var model;
        _.delay(this.indicateLoading, delayTime);
        model = callback.apply(this, args);
        this.listenTo(model, 'sync', this.removeLoadingIndicator);
        return this.listenTo(model, 'finished', this.removeLoadingIndicator);
      };

      Router.prototype._parseParameters = function(params) {
        var parsedParams;
        parsedParams = {};
        _(params.split('&')).each((function(_this) {
          return function(query) {
            var k, v, _ref;
            _ref = query.split('=', 2), k = _ref[0], v = _ref[1];
            if (v.match(/,/)) {
              v = v.split(',');
            } else {
              v = [v];
            }
            return parsedParams[k] = v;
          };
        })(this));
        parsedParams;
        if (_(params).has('titlebar')) {
          return app.getRegion('navigation').show(new TitleBarView(this.appState.divisions));
        }
      };

      Router.prototype.indicateLoading = function() {
        return spinner.start();
      };

      Router.prototype.removeLoadingIndicator = function() {
        return spinner != null ? spinner.stop() : void 0;
      };

      return Router;

    })(Marionette.AppRouter);
    return Router;
  });

}).call(this);

//# sourceMappingURL=embedded-router.js.map
