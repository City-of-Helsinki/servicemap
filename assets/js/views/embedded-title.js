(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/p13n', 'cs!app/jade', 'cs!app/views/base', 'URI'], function(p13n, jade, base, URI) {
    var TitleView;
    return TitleView = (function(_super) {
      __extends(TitleView, _super);

      function TitleView() {
        this.render = __bind(this.render, this);
        return TitleView.__super__.constructor.apply(this, arguments);
      }

      TitleView.prototype.initialize = function(_arg) {
        this.href = _arg.href;
      };

      TitleView.prototype.className = 'title-control';

      TitleView.prototype.render = function() {
        this.el.innerHTML = jade.template('embedded-title', {
          lang: p13n.getLanguage(),
          href: this.href
        });
        return this.el;
      };

      return TitleView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=embedded-title.js.map
