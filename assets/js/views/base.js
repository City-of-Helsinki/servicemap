(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['backbone.marionette', 'cs!app/jade', 'cs!app/base'], function(Marionette, jade, _arg) {
    var KeyboardHandlerMixin, SMCollectionView, SMItemView, SMLayout, SMTemplateMixin, mixOf;
    mixOf = _arg.mixOf;
    SMTemplateMixin = (function() {
      function SMTemplateMixin() {}

      SMTemplateMixin.prototype.mixinTemplateHelpers = function(data) {
        jade.mixinHelpers(data);
        return data;
      };

      SMTemplateMixin.prototype.getTemplate = function() {
        return jade.getTemplate(this.template);
      };

      return SMTemplateMixin;

    })();
    KeyboardHandlerMixin = (function() {
      function KeyboardHandlerMixin() {
        this.keyboardHandler = __bind(this.keyboardHandler, this);
      }

      KeyboardHandlerMixin.prototype.keyboardHandler = function(callback, keys) {
        var codes, handle;
        codes = _(keys).map((function(_this) {
          return function(key) {
            switch (key) {
              case 'enter':
                return 13;
              case 'space':
                return 32;
            }
          };
        })(this));
        handle = _.bind(callback, this);
        return (function(_this) {
          return function(event) {
            var _ref;
            event.stopPropagation();
            if (_ref = event.which, __indexOf.call(codes, _ref) >= 0) {
              return handle(event);
            }
          };
        })(this);
      };

      return KeyboardHandlerMixin;

    })();
    return {
      SMItemView: SMItemView = (function(_super) {
        __extends(SMItemView, _super);

        function SMItemView() {
          return SMItemView.__super__.constructor.apply(this, arguments);
        }

        return SMItemView;

      })(mixOf(Marionette.ItemView, SMTemplateMixin, KeyboardHandlerMixin)),
      SMCollectionView: SMCollectionView = (function(_super) {
        __extends(SMCollectionView, _super);

        function SMCollectionView() {
          return SMCollectionView.__super__.constructor.apply(this, arguments);
        }

        return SMCollectionView;

      })(mixOf(Marionette.CollectionView, SMTemplateMixin, KeyboardHandlerMixin)),
      SMLayout: SMLayout = (function(_super) {
        __extends(SMLayout, _super);

        function SMLayout() {
          return SMLayout.__super__.constructor.apply(this, arguments);
        }

        return SMLayout;

      })(mixOf(Marionette.Layout, SMTemplateMixin, KeyboardHandlerMixin))
    };
  });

}).call(this);

//# sourceMappingURL=base.js.map
