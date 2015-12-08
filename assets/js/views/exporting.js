(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'URI', 'backbone', 'cs!app/views/base', 'cs!app/views/context-menu', 'cs!app/p13n', 'i18next'], function(_, URI, Backbone, base, ContextMenu, p13n, i18n) {
    var ExportingView;
    return ExportingView = (function(_super) {
      __extends(ExportingView, _super);

      function ExportingView() {
        return ExportingView.__super__.constructor.apply(this, arguments);
      }

      ExportingView.prototype.template = 'exporting';

      ExportingView.prototype.regions = {
        exportingContext: '#exporting-context'
      };

      ExportingView.prototype.events = {
        'click': 'openMenu'
      };

      ExportingView.prototype.openMenu = function(ev) {
        var menu, models;
        ev.preventDefault();
        ev.stopPropagation();
        if (this.exportingContext.currentView != null) {
          this.exportingContext.reset();
          return;
        }
        models = [
          new Backbone.Model({
            name: i18n.t('tools.embed_action'),
            action: _.bind(this.exportEmbed, this)
          })
        ];
        menu = new ContextMenu({
          collection: new Backbone.Collection(models)
        });
        this.exportingContext.show(menu);
        return $(document).one('click', (function(_this) {
          return function(ev) {
            return _this.exportingContext.reset();
          };
        })(this));
      };

      ExportingView.prototype.exportEmbed = function(ev) {
        var background, city, directory, query, url;
        url = URI(window.location.href);
        directory = url.directory();
        directory = '/embedder' + directory;
        url.directory(directory);
        url.port('');
        query = url.search(true);
        query.bbox = this.getMapBoundsBbox();
        city = p13n.get('city');
        if (city != null) {
          query.city = city;
        }
        background = p13n.get('map_background_layer');
        if (background !== 'servicemap' && background !== 'guidemap') {
          query.map = background;
        }
        query.ratio = parseInt(100 * window.innerHeight / window.innerWidth);
        url.search(query);
        return window.location.href = url.toString();
      };

      ExportingView.prototype.getMapBoundsBbox = function() {
        var rightBbox, wrongBbox, __you_shouldnt_access_me_like_this;
        __you_shouldnt_access_me_like_this = window.mapView.map;
        wrongBbox = __you_shouldnt_access_me_like_this._originalGetBounds().toBBoxString().split(',');
        rightBbox = _.map([1, 0, 3, 2], function(i) {
          return wrongBbox[i].slice(0, 8);
        });
        return rightBbox.join(',');
      };

      ExportingView.prototype.render = function() {
        ExportingView.__super__.render.call(this);
        return this.el;
      };

      return ExportingView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=exporting.js.map
