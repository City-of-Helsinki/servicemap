(function() {
  define(['underscore', 'raven', 'backbone', 'cs!app/models'], function(_, Raven, Backbone, models) {
    var BASE_URL, LANGUAGES, TIMEOUT, currentId, fetchAccessibilitySentences, ids, _buildTranslatedObject, _generateId, _parse;
    BASE_URL = 'http://www.hel.fi/palvelukarttaws/rest/v3/unit/';
    LANGUAGES = ['fi', 'sv', 'en'];
    TIMEOUT = 10000;
    _buildTranslatedObject = function(data, base) {
      return _.object(_.map(LANGUAGES, function(lang) {
        return [lang, data["" + base + "_" + lang]];
      }));
    };
    currentId = 0;
    ids = {};
    _generateId = function(content) {
      if (!(content in ids)) {
        ids[content] = currentId;
        currentId += 1;
      }
      return ids[content];
    };
    _parse = function(data) {
      var groups, sentences;
      sentences = {};
      groups = {};
      _.each(data.accessibility_sentences, function(sentence) {
        var group, key;
        group = _buildTranslatedObject(sentence, 'sentence_group');
        key = _generateId(group.fi);
        groups[key] = group;
        if (!(key in sentences)) {
          sentences[key] = [];
        }
        return sentences[key].push(_buildTranslatedObject(sentence, 'sentence'));
      });
      return {
        groups: groups,
        sentences: sentences
      };
    };
    fetchAccessibilitySentences = function(unit, callback) {
      var args;
      args = {
        dataType: 'jsonp',
        url: BASE_URL + unit.id,
        jsonpCallback: 'jcbAsc',
        cache: true,
        success: function(data) {
          return callback(_parse(data));
        },
        timeout: TIMEOUT,
        error: function(jqXHR, errorType, exception) {
          var context;
          context = {
            tags: {
              type: 'helfi_rest_api'
            },
            extra: {
              error_type: errorType,
              jqXHR: jqXHR
            }
          };
          if (errorType === 'timeout') {
            Raven.captureException(new Error("Timeout of " + TIMEOUT + "ms reached for " + (BASE_URL + unit.id)), context);
          } else {
            Raven.captureException(exception, context);
          }
          return callback({
            error: true
          });
        }
      };
      return this.xhr = $.ajax(args);
    };
    return {
      fetch: fetchAccessibilitySentences
    };
  });

}).call(this);

//# sourceMappingURL=accessibility-sentences.js.map
