(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['backbone.marionette', 'URI'], function(Marionette, URI) {
    var BaseRouter;
    return BaseRouter = (function(_super) {
      __extends(BaseRouter, _super);

      function BaseRouter() {
        return BaseRouter.__super__.constructor.apply(this, arguments);
      }

      BaseRouter.prototype.initialize = function(options) {
        BaseRouter.__super__.initialize.call(this, options);
        this.controller = options.controller;
        this.makeMapView = options.makeMapView;
        this.appRoute(/^\/?([^\/]*)$/, 'renderHome');
        this.appRoute(/^unit\/?([^\/]*)$/, 'renderUnit');
        this.appRoute(/^division\/?(.*?)$/, 'renderDivision');
        this.appRoute(/^address\/(.*?)$/, 'renderAddress');
        this.appRoute(/^search(\?[^\/]*)$/, 'renderSearch');
        return this.appRoute(/^division(\?.*?)$/, 'renderMultipleDivisions');
      };

      BaseRouter.prototype.onPostRouteExecute = function() {};

      BaseRouter.prototype.executeRoute = function(callback, args, context) {
        var _ref;
        return callback != null ? (_ref = callback.apply(this, args)) != null ? _ref.done((function(_this) {
          return function(opts) {
            var mapOpts;
            mapOpts = {};
            if (context.query != null) {
              mapOpts.bbox = context.query.bbox;
              mapOpts.level = context.query.level;
            }
            _this.makeMapView(mapOpts);
            if (opts != null) {
              if (typeof opts.afterMapInit === "function") {
                opts.afterMapInit();
              }
            }
            return _this.onPostRouteExecute();
          };
        })(this)) : void 0 : void 0;
      };

      BaseRouter.prototype.processQuery = function(q) {
        if ((q.bbox != null) && q.bbox.match(/([0-9]+\.?[0-9+],)+[0-9]+\.?[0-9+]/)) {
          q.bbox = q.bbox.split(',');
        }
        if ((q.ocd_id != null) && q.ocd_id.match(/([^,]+,)*[^,]+/)) {
          q.ocdId = q.ocd_id.split(',');
          delete q.ocd_id;
        }
        return q;
      };

      BaseRouter.prototype.execute = function(callback, args) {
        var context, fullUri, lastArg, newArgs;
        context = {};
        lastArg = args[args.length - 1];
        fullUri = new URI(window.location.toString());
        if (!(args.length < 1 || lastArg === null)) {
          newArgs = URI(lastArg).segment();
        } else {
          newArgs = [];
        }
        if (fullUri.query()) {
          context.query = this.processQuery(fullUri.search(true));
          if (context.query.map != null) {
            p13n.setMapBackgroundLayer(context.query.map);
          }
          if (context.query.city != null) {
            p13n.set('city', context.query.city);
          }
          newArgs.push(context);
        }
        return this.executeRoute(callback, newArgs, context);
      };

      BaseRouter.prototype.routeEmbedded = function(uri) {
        var callback, path, relativeUri, resource;
        path = uri.segment();
        resource = path[0];
        callback = (function() {
          if (resource === 'division') {
            if ('ocd_id' in uri.search(true)) {
              return 'renderMultipleDivisions';
            } else {
              return 'renderDivision';
            }
          } else {
            switch (resource) {
              case '':
                return 'renderHome';
              case 'unit':
                return 'renderUnit';
              case 'search':
                return 'renderSearch';
              case 'address':
                return 'renderAddress';
            }
          }
        })();
        uri.segment(0, '');
        relativeUri = new URI(uri.pathname() + uri.search());
        callback = _.bind(this.controller[callback], this.controller);
        return this.execute(callback, [relativeUri.toString()]);
      };

      return BaseRouter;

    })(Backbone.Marionette.AppRouter);
  });

}).call(this);

//# sourceMappingURL=router.js.map
