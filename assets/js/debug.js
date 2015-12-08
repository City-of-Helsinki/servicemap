(function() {
  var __slice = [].slice;

  define(['backbone'], function(Backbone) {
    var EventDebugger, STATEFUL_EVENT, debugEvents, debugVariables, exports, log;
    debugVariables = ['units', 'services', 'selectedUnits', 'selectedEvents', 'searchResults', 'searchState'];
    debugEvents = ['all'];
    log = function(x) {
      return console.log(x);
    };
    STATEFUL_EVENT = (function() {
      function STATEFUL_EVENT() {}

      return STATEFUL_EVENT;

    })();
    EventDebugger = (function() {
      function EventDebugger(appControl) {
        this.appControl = appControl;
        _.extend(this, Backbone.Events);
        this.addListeners();
      }

      EventDebugger.prototype.addListeners = function() {
        var eventSpec, interceptor, variableName, _i, _len, _results;
        interceptor = function(variableName) {
          return function() {
            var data, eventName, i, param, rest, target, _i, _len;
            eventName = arguments[0], target = arguments[1], rest = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
            data = new STATEFUL_EVENT;
            data.variable = variableName;
            data.event = eventName;
            data.target = (target != null ? typeof target.toJSON === "function" ? target.toJSON() : void 0 : void 0) || target;
            for (i = _i = 0, _len = rest.length; _i < _len; i = ++_i) {
              param = rest[i];
              data["param_" + (i + 1)] = param;
            }
            return log(data);
          };
        };
        _results = [];
        for (_i = 0, _len = debugVariables.length; _i < _len; _i++) {
          variableName = debugVariables[_i];
          _results.push((function() {
            var _j, _len1, _results1;
            _results1 = [];
            for (_j = 0, _len1 = debugEvents.length; _j < _len1; _j++) {
              eventSpec = debugEvents[_j];
              _results1.push(this.listenTo(this.appControl[variableName], eventSpec, interceptor(variableName)));
            }
            return _results1;
          }).call(this));
        }
        return _results;
      };

      return EventDebugger;

    })();
    return exports = {
      EventDebugger: EventDebugger,
      log: log
    };
  });

}).call(this);

//# sourceMappingURL=debug.js.map
