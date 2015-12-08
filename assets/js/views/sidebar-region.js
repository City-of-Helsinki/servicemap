(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['underscore', 'backbone.marionette', 'cs!app/jade', 'cs!app/animations'], function(_, Marionette, jade, animations) {
    var SidebarRegion;
    SidebarRegion = (function(_super) {
      var SUPPORTED_ANIMATIONS;

      __extends(SidebarRegion, _super);

      function SidebarRegion() {
        this.show = __bind(this.show, this);
        this._trigger = __bind(this._trigger, this);
        return SidebarRegion.__super__.constructor.apply(this, arguments);
      }

      SUPPORTED_ANIMATIONS = ['left', 'right'];

      SidebarRegion.prototype._trigger = function(eventName, view) {
        Marionette.triggerMethod.call(this, eventName, view);
        if (_.isFunction(view.triggerMethod)) {
          return view.triggerMethod(eventName);
        } else {
          return Marionette.triggerMethod.call(view, eventName);
        }
      };

      SidebarRegion.prototype.show = function(view, options) {
        var $container, $newContent, $oldContent, animationCallback, animationType, data, isDifferentView, isViewClosed, preventClose, shouldAnimate, showOptions, templateString, _ref, _shouldCloseView;
        showOptions = options || {};
        this.ensureEl();
        isViewClosed = view.isClosed || _.isUndefined(view.$el);
        isDifferentView = view !== this.currentView;
        preventClose = !!showOptions.preventClose;
        _shouldCloseView = !preventClose && isDifferentView;
        animationType = showOptions.animationType;
        $oldContent = (_ref = this.currentView) != null ? _ref.$el : void 0;
        shouldAnimate = ($oldContent != null ? $oldContent.length : void 0) && __indexOf.call(SUPPORTED_ANIMATIONS, animationType) >= 0 && (view.template != null);
        if (shouldAnimate) {
          data = (typeof view.serializeData === "function" ? view.serializeData() : void 0) || {};
          templateString = jade.template(view.template, data);
          $container = this.$el;
          $newContent = view.$el.append($(templateString));
          this._trigger('before:render', view);
          this._trigger('before:show', view);
          animationCallback = (function(_this) {
            return function() {
              if (_shouldCloseView) {
                _this.close();
              }
              _this.currentView = view;
              _this._trigger('render', view);
              return _this._trigger('show', view);
            };
          })(this);
          animations.render($container, $oldContent, $newContent, animationType, animationCallback);
        } else {
          if (_shouldCloseView) {
            this.close();
          }
          view.render();
          this._trigger('before:show', view);
          if (isDifferentView || isViewClosed) {
            this.open(view);
          }
          this.currentView = view;
          this._trigger('show', view);
        }
        return this;
      };

      SidebarRegion.prototype.close = function() {
        var view;
        view = this.currentView;
        if (!view || view.isClosed) {
          return;
        }
        if (view.close) {
          view.close();
        } else if (view.remove) {
          view.remove();
        }
        Marionette.triggerMethod.call(this, 'close', view);
        return delete this.currentView;
      };

      return SidebarRegion;

    })(Marionette.Region);
    return SidebarRegion;
  });

}).call(this);

//# sourceMappingURL=sidebar-region.js.map
