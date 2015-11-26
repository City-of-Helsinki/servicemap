(function() {
  "use strict";
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['underscore', 'backbone'], function(_, Backbone) {
    var Accessibility;
    Accessibility = (function() {
      function Accessibility() {
        this._requestData = __bind(this._requestData, this);
        _.extend(this, Backbone.Events);
        this._requestData();
      }

      Accessibility.prototype._requestData = function() {
        var settings;
        settings = {
          url: "" + appSettings.service_map_backend + "/accessibility_rule/",
          success: (function(_this) {
            return function(data) {
              _this.rules = data.rules;
              _this.messages = data.messages;
              return _this.trigger('change');
            };
          })(this),
          error: (function(_this) {
            return function(data) {
              throw new Error("Unable to retrieve accessibility data");
            };
          })(this)
        };
        return Backbone.ajax(settings);
      };

      Accessibility.prototype._emitShortcoming = function(rule, messages) {
        var currentMessages, msg, requirementId, segment, segmentMessages;
        if (rule.msg === null || !(rule.msg in this.messages)) {
          return;
        }
        msg = this.messages[rule.msg];
        if (msg != null) {
          segment = rule.path[0];
          if (!(segment in messages)) {
            messages[segment] = [];
          }
          segmentMessages = messages[segment];
          requirementId = rule.requirement_id;
          if (!(requirementId in segmentMessages)) {
            segmentMessages[requirementId] = [];
          }
          currentMessages = segmentMessages[requirementId];
          if (rule.id === requirementId) {
            if (!currentMessages.length) {
              currentMessages.push(msg);
            }
          } else {
            currentMessages.push(msg);
          }
        }
      };

      Accessibility.prototype._calculateShortcomings = function(rule, properties, messages, level) {
        var isOkay, op, prop, retValues, val, _i, _len, _ref, _ref1;
        if (level == null) {
          level = None;
        }
        if (!(rule.operands[0] instanceof Object)) {
          op = rule.operands;
          prop = properties[op[0]];
          if (!prop) {
            return true;
          }
          val = op[1];
          if (rule.operator === 'NEQ') {
            isOkay = prop !== val;
          } else if (rule.operator === 'EQ') {
            isOkay = prop === val;
          } else {
            throw new Error("invalid operator " + rule.operator);
          }
          if (!isOkay) {
            this._emitShortcoming(rule, messages);
          }
          return isOkay;
        }
        retValues = [];
        _ref = rule.operands;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          op = _ref[_i];
          isOkay = this._calculateShortcomings(op, properties, messages, level = level + 1);
          retValues.push(isOkay);
        }
        if ((_ref1 = rule.operator) !== 'AND' && _ref1 !== 'OR') {
          throw new Error("invalid operator " + rule.operator);
        }
        if (rule.operator === 'AND' && __indexOf.call(retValues, false) < 0) {
          return true;
        }
        if (rule.operator === 'OR' && __indexOf.call(retValues, true) >= 0) {
          return true;
        }
        this._emitShortcoming(rule, messages);
        return false;
      };

      Accessibility.prototype.getShortcomings = function(properties, profile) {
        var level, messages, p, propById, rule, _i, _len;
        if (this.rules == null) {
          return {
            status: 'pending'
          };
        }
        propById = {};
        for (_i = 0, _len = properties.length; _i < _len; _i++) {
          p = properties[_i];
          propById[p.variable] = p.value;
        }
        messages = {};
        rule = this.rules[profile];
        level = 0;
        this._calculateShortcomings(rule, propById, messages, level = level);
        return {
          status: 'complete',
          messages: messages
        };
      };

      Accessibility.prototype.getTranslatedShortcomings = function(profiles, model) {
        var gatheredMessages, messages, msg, pid, requirementId, seen, segmentId, segmentMessages, shortcoming, shortcomings, translated, _i, _j, _len, _len1, _ref, _ref1;
        shortcomings = {};
        seen = {};
        _ref = _.keys(profiles);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pid = _ref[_i];
          shortcoming = this.getShortcomings(model.get('accessibility_properties'), pid);
          if (shortcoming.status !== 'complete') {
            return {
              status: 'pending',
              results: {}
            };
          }
          if (_.keys(shortcoming.messages).length) {
            _ref1 = shortcoming.messages;
            for (segmentId in _ref1) {
              segmentMessages = _ref1[segmentId];
              shortcomings[segmentId] = shortcomings[segmentId] || {};
              for (requirementId in segmentMessages) {
                messages = segmentMessages[requirementId];
                gatheredMessages = [];
                for (_j = 0, _len1 = messages.length; _j < _len1; _j++) {
                  msg = messages[_j];
                  translated = p13n.getTranslatedAttr(msg);
                  if (!(translated in seen)) {
                    seen[translated] = true;
                    gatheredMessages.push(msg);
                  }
                }
                if (gatheredMessages.length) {
                  shortcomings[segmentId][requirementId] = gatheredMessages;
                }
              }
            }
          }
        }
        return {
          status: 'success',
          results: shortcomings
        };
      };

      return Accessibility;

    })();
    return new Accessibility;
  });

}).call(this);

//# sourceMappingURL=accessibility.js.map
