(function() {
  define(['underscore', 'jquery', 'i18next', 'cs!app/p13n', 'cs!app/dateformat'], function(_, $, i18n, p13n, dateformat) {
    var Jade, setHelper;
    if (typeof jade !== 'object') {
      throw new Error("Jade not loaded before app");
    }
    setHelper = function(data, name, helper) {
      if (name in data) {
        return;
      }
      return data[name] = helper;
    };
    Jade = (function() {
      function Jade() {}

      Jade.prototype.getTemplate = function(name) {
        var key, templateFunc;
        key = "views/templates/" + name;
        if (!(key in JST)) {
          throw new Error("template '" + name + "' not loaded");
        }
        templateFunc = JST[key];
        return templateFunc;
      };

      Jade.prototype.tAttr = function(attr) {
        return p13n.getTranslatedAttr(attr);
      };

      Jade.prototype.tAttrHasLang = function(attr) {
        if (!attr) {
          return false;
        }
        return p13n.getLanguage() in attr;
      };

      Jade.prototype.phoneI18n = function(num) {
        if (num.indexOf('0' === 0)) {
          num = '+358' + num.substring(1);
        }
        num = num.replace(/\s/g, '');
        num = num.replace(/-/g, '');
        return num;
      };

      Jade.prototype.staticPath = function(path) {
        if (path.indexOf('/') === 0) {
          path = path.substring(1);
        }
        return appSettings.static_path + path;
      };

      Jade.prototype.humanDateRange = function(startTime, endTime) {
        var formatted, hasEndTime;
        formatted = dateformat.humanizeEventDatetime(startTime, endTime, 'small', hasEndTime = false);
        return formatted.date;
      };

      Jade.prototype.humanDistance = function(meters) {
        var a, b, val, _ref;
        if (meters === Number.MAX_VALUE) {
          return "?";
        } else if (meters < 1000) {
          return "" + (Math.ceil(meters)) + "m";
        } else {
          val = Math.ceil(meters / 100).toString();
          _ref = [val.slice(0, -1), val.slice(-1)], a = _ref[0], b = _ref[1];
          if (b !== "0") {
            return "" + a + "." + b + "km";
          } else {
            return "" + a + "km";
          }
        }
      };

      Jade.prototype.humanShortcomings = function(count) {
        if (count === Number.MAX_VALUE) {
          return i18n.t('accessibility.no_data');
        } else if (count === 0) {
          return i18n.t('accessibility.no_shortcomings');
        } else {
          return i18n.t('accessibility.shortcoming_count', {
            count: count
          });
        }
      };

      Jade.prototype.humanDate = function(datetime) {
        var res;
        return res = dateformat.humanizeSingleDatetime(datetime);
      };

      Jade.prototype.uppercaseFirst = function(val) {
        return val.charAt(0).toUpperCase() + val.slice(1);
      };

      Jade.prototype.mixinHelpers = function(data) {
        setHelper(data, 't', i18n.t);
        setHelper(data, 'tAttr', this.tAttr);
        setHelper(data, 'tAttrHasLang', this.tAttrHasLang);
        setHelper(data, 'phoneI18n', this.phoneI18n);
        setHelper(data, 'staticPath', this.staticPath);
        setHelper(data, 'humanDateRange', this.humanDateRange);
        setHelper(data, 'humanDate', this.humanDate);
        setHelper(data, 'humanDistance', this.humanDistance);
        setHelper(data, 'uppercaseFirst', this.uppercaseFirst);
        setHelper(data, 'humanShortcomings', this.humanShortcomings);
        setHelper(data, 'pad', (function(_this) {
          return function(s) {
            return " " + s + " ";
          };
        })(this));
        return data;
      };

      Jade.prototype.template = function(name, locals) {
        var data, func, templateStr;
        if (locals != null) {
          if (typeof locals !== 'object') {
            throw new Error("template must get an object argument");
          }
        } else {
          locals = {};
        }
        func = this.getTemplate(name);
        data = _.clone(locals);
        this.mixinHelpers(data);
        templateStr = func(data);
        return $.trim(templateStr);
      };

      return Jade;

    })();
    return new Jade;
  });

}).call(this);

//# sourceMappingURL=jade.js.map
