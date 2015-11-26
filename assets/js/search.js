(function() {
  define(['backbone', 'typeahead.bundle', 'cs!app/p13n', 'cs!app/settings'], function(Backbone, ta, p13n, settings) {
    var lang, linkedeventsEngine, servicemapEngine;
    lang = p13n.getLanguage();
    servicemapEngine = new Bloodhound({
      name: 'suggestions',
      remote: {
        url: appSettings.service_map_backend + ("/search/?language=" + lang + "&page_size=4&input="),
        replace: (function(_this) {
          return function(url, query) {
            var city;
            url += query;
            city = p13n.get('city');
            if (city) {
              url += "&municipality=" + city;
            }
            return url;
          };
        })(this),
        ajax: settings.applyAjaxDefaults({}),
        filter: function(parsedResponse) {
          return parsedResponse.results;
        },
        rateLimitWait: 50
      },
      datumTokenizer: function(datum) {
        return Bloodhound.tokenizers.whitespace(datum.name[lang]);
      },
      queryTokenizer: Bloodhound.tokenizers.whitespace
    });
    linkedeventsEngine = new Bloodhound({
      name: 'events_suggestions',
      remote: {
        url: appSettings.linkedevents_backend + ("/search/?language=" + lang + "&page_size=4&input=%QUERY"),
        ajax: settings.applyAjaxDefaults({}),
        filter: function(parsedResponse) {
          return parsedResponse.data;
        },
        rateLimitWait: 50
      },
      datumTokenizer: function(datum) {
        return Bloodhound.tokenizers.whitespace(datum.name[lang]);
      },
      queryTokenizer: Bloodhound.tokenizers.whitespace
    });
    servicemapEngine.initialize();
    linkedeventsEngine.initialize();
    return {
      linkedeventsEngine: linkedeventsEngine,
      servicemapEngine: servicemapEngine
    };
  });

}).call(this);

//# sourceMappingURL=search.js.map
