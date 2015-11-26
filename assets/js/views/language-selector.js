(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'cs!app/models', 'cs!app/views/base'], function(_, models, base) {
    var LanguageSelectorView;
    return LanguageSelectorView = (function(_super) {
      __extends(LanguageSelectorView, _super);

      function LanguageSelectorView() {
        return LanguageSelectorView.__super__.constructor.apply(this, arguments);
      }

      LanguageSelectorView.prototype.template = 'language-selector';

      LanguageSelectorView.prototype.languageSubdomain = {
        fi: 'palvelukartta',
        sv: 'servicekarta',
        en: 'servicemap'
      };

      LanguageSelectorView.prototype.initialize = function(opts) {
        this.p13n = opts.p13n;
        this.languages = this.p13n.getSupportedLanguages();
        this.refreshCollection();
        return this.listenTo(p13n, 'url', (function(_this) {
          return function() {
            return _this.render();
          };
        })(this));
      };

      LanguageSelectorView.prototype.selectLanguage = function(ev) {
        var l;
        l = $(ev.currentTarget).data('language');
        return window.location.reload();
      };

      LanguageSelectorView.prototype._replaceUrl = function(withWhat) {
        var href;
        href = window.location.href;
        if (href.match(/^http[s]?:\/\/[^.]+\.hel\..*/)) {
          return href.replace(/\/\/[^.]+./, "//" + withWhat + ".");
        } else {
          return href;
        }
      };

      LanguageSelectorView.prototype.serializeData = function() {
        var data, i, val, _ref;
        data = LanguageSelectorView.__super__.serializeData.call(this);
        _ref = data.items;
        for (i in _ref) {
          val = _ref[i];
          val.link = this._replaceUrl(this.languageSubdomain[val.code]);
        }
        return data;
      };

      LanguageSelectorView.prototype.refreshCollection = function() {
        var languageModels, selected;
        selected = this.p13n.getLanguage();
        languageModels = _.map(this.languages, function(l) {
          return new models.Language({
            code: l.code,
            name: l.name,
            selected: l.code === selected
          });
        });
        return this.collection = new models.LanguageList(_.filter(languageModels, function(l) {
          return !l.get('selected');
        }));
      };

      return LanguageSelectorView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=language-selector.js.map
