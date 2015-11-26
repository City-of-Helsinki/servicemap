(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/views/base'], function(base) {
    var ContextMenuCollectionView, ContextMenuView, ToolMenuItem;
    ToolMenuItem = (function(_super) {
      __extends(ToolMenuItem, _super);

      function ToolMenuItem() {
        return ToolMenuItem.__super__.constructor.apply(this, arguments);
      }

      ToolMenuItem.prototype.className = 'context-menu-item';

      ToolMenuItem.prototype.tagName = 'li';

      ToolMenuItem.prototype.template = 'context-menu-item';

      ToolMenuItem.prototype.initialize = function(opts) {
        ToolMenuItem.__super__.initialize.call(this, opts);
        return this.$el.on('click', this.model.get('action'));
      };

      return ToolMenuItem;

    })(base.SMItemView);
    ContextMenuCollectionView = (function(_super) {
      __extends(ContextMenuCollectionView, _super);

      function ContextMenuCollectionView() {
        return ContextMenuCollectionView.__super__.constructor.apply(this, arguments);
      }

      ContextMenuCollectionView.prototype.className = 'context-menu';

      ContextMenuCollectionView.prototype.tagName = 'ul';

      ContextMenuCollectionView.prototype.itemView = ToolMenuItem;

      return ContextMenuCollectionView;

    })(base.SMCollectionView);
    ContextMenuView = (function(_super) {
      __extends(ContextMenuView, _super);

      function ContextMenuView() {
        return ContextMenuView.__super__.constructor.apply(this, arguments);
      }

      ContextMenuView.prototype.className = 'context-menu-wrapper';

      ContextMenuView.prototype.template = 'context-menu-wrapper';

      ContextMenuView.prototype.initialize = function(opts) {
        this.opts = opts;
      };

      ContextMenuView.prototype.regions = {
        contents: '.contents'
      };

      ContextMenuView.prototype.onRender = function() {
        return this.contents.show(new ContextMenuCollectionView(this.opts));
      };

      return ContextMenuView;

    })(base.SMLayout);
    return ContextMenuView;
  });

}).call(this);

//# sourceMappingURL=context-menu.js.map
