(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/p13n', 'cs!app/jade', 'cs!app/views/base'], function(p13n, jade, base) {
    var LandingTitleView, TitleView;
    TitleView = (function(_super) {
      __extends(TitleView, _super);

      function TitleView() {
        this.render = __bind(this.render, this);
        return TitleView.__super__.constructor.apply(this, arguments);
      }

      TitleView.prototype.className = 'title-control';

      TitleView.prototype.render = function() {
        this.el.innerHTML = jade.template('title-view', {
          lang: p13n.getLanguage(),
          root: appSettings.url_prefix
        });
        return this.el;
      };

      return TitleView;

    })(base.SMItemView);
    LandingTitleView = (function(_super) {
      __extends(LandingTitleView, _super);

      function LandingTitleView() {
        return LandingTitleView.__super__.constructor.apply(this, arguments);
      }

      LandingTitleView.prototype.template = 'landing-title-view';

      LandingTitleView.prototype.id = 'title';

      LandingTitleView.prototype.className = 'landing-title-control';

      LandingTitleView.prototype.initialize = function() {
        this.listenTo(app.vent, 'title-view:hide', this.hideTitleView);
        return this.listenTo(app.vent, 'title-view:show', this.unHideTitleView);
      };

      LandingTitleView.prototype.serializeData = function() {
        return {
          isHidden: this.isHidden,
          lang: p13n.getLanguage()
        };
      };

      LandingTitleView.prototype.hideTitleView = function() {
        $('body').removeClass('landing');
        this.isHidden = true;
        return this.render();
      };

      LandingTitleView.prototype.unHideTitleView = function() {
        $('body').addClass('landing');
        this.isHidden = false;
        return this.render();
      };

      return LandingTitleView;

    })(base.SMItemView);
    return {
      TitleView: TitleView,
      LandingTitleView: LandingTitleView
    };
  });

}).call(this);

//# sourceMappingURL=title.js.map
