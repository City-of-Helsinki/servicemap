(function() {
  define(function() {
    var applyAjaxDefaults, ieVersion;
    ieVersion = getIeVersion();
    applyAjaxDefaults = function(settings) {
      settings.cache = true;
      if (!ieVersion) {
        return settings;
      }
      if (ieVersion >= 10) {
        return settings;
      }
      settings.dataType = 'jsonp';
      settings.data = settings.data || {};
      settings.data.format = 'jsonp';
      return settings;
    };
    return {
      applyAjaxDefaults: applyAjaxDefaults
    };
  });

}).call(this);

//# sourceMappingURL=settings.js.map
