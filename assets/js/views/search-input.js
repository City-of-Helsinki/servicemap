(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['typeahead.bundle', 'cs!app/models', 'cs!app/jade', 'cs!app/search', 'cs!app/geocoding', 'cs!app/views/base'], function(typeahead, models, jade, search, geocoding, base) {
    var SearchInputView;
    return SearchInputView = (function(_super) {
      __extends(SearchInputView, _super);

      function SearchInputView() {
        return SearchInputView.__super__.constructor.apply(this, arguments);
      }

      SearchInputView.prototype.classname = 'search-input-element';

      SearchInputView.prototype.template = 'navigation-search';

      SearchInputView.prototype.initialize = function(model, searchResults) {
        this.model = model;
        this.searchResults = searchResults;
        this.listenTo(this.searchResults, 'ready', this.adaptToQuery);
        return this.listenTo(this.searchResults, 'reset', (function(_this) {
          return function() {
            if (_this.searchResults.isEmpty()) {
              return _this.setInputText('');
            }
          };
        })(this));
      };

      SearchInputView.prototype.adaptToQuery = function(model, value, opts) {
        var $container, $icon, _ref;
        $container = this.$el.find('.action-button');
        $icon = $container.find('span');
        if (this.isEmpty()) {
          if ((_ref = this.searchResults.query) != null ? _ref.length : void 0) {
            this.setInputText(this.searchResults.query);
            this.trigger('open');
          }
        }
        if (this.isEmpty() || this.getInputText() === this.searchResults.query) {
          $icon.removeClass('icon-icon-forward-bold');
          $icon.addClass('icon-icon-close');
          $container.removeClass('search-button');
          return $container.addClass('close-button');
        } else {
          $icon.addClass('icon-icon-forward-bold');
          $icon.removeClass('icon-icon-close');
          $container.removeClass('close-button');
          return $container.addClass('search-button');
        }
      };

      SearchInputView.prototype.events = {
        'typeahead:selected': 'autosuggestShowDetails',
        'click .tt-suggestion': function(e) {
          return e.stopPropagation();
        },
        'click input': '_onInputClicked',
        'click .typeahead-suggestion.fulltext': 'executeQuery',
        'click .action-button.search-button': 'search',
        'submit .input-container': 'search',
        'input input': 'checkInputValue'
      };

      SearchInputView.prototype.checkInputValue = function() {
        if (this.isEmpty()) {
          this.$searchEl.typeahead('val', '');
          return app.commands.execute('clearSearchResults', {
            navigate: true
          });
        }
      };

      SearchInputView.prototype.search = function(e) {
        e.stopPropagation();
        if (!this.isEmpty()) {
          this.$searchEl.typeahead('close');
          this.executeQuery();
        }
        return e.preventDefault();
      };

      SearchInputView.prototype.isEmpty = function() {
        var query;
        query = this.getInputText();
        if ((query != null) && query.length > 0) {
          return false;
        }
        return true;
      };

      SearchInputView.prototype._onInputClicked = function(ev) {
        this.trigger('open');
        return ev.stopPropagation();
      };

      SearchInputView.prototype._getSearchEl = function() {
        if (this.$searchEl != null) {
          return this.$searchEl;
        } else {
          return this.$searchEl = this.$el.find('input.form-control[type=search]');
        }
      };

      SearchInputView.prototype.setInputText = function(query) {
        var $el;
        $el = this._getSearchEl();
        if ($el.length) {
          return $el.typeahead('val', query);
        }
      };

      SearchInputView.prototype.getInputText = function() {
        var $el;
        $el = this._getSearchEl();
        if ($el.length) {
          return $el.typeahead('val');
        } else {
          return null;
        }
      };

      SearchInputView.prototype.onRender = function() {
        this.enableTypeahead('input.form-control[type=search]');
        this.setTypeaheadWidth();
        return $(window).resize((function(_this) {
          return function() {
            return _this.setTypeaheadWidth();
          };
        })(this));
      };

      SearchInputView.prototype.setTypeaheadWidth = function() {
        var width, windowWidth;
        windowWidth = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
        if (windowWidth < appSettings.mobile_ui_breakpoint) {
          width = $('#navigation-header').width();
          return this.$el.find('.tt-dropdown-menu').css({
            'width': width
          });
        } else {
          return this.$el.find('.tt-dropdown-menu').css({
            'width': 'auto'
          });
        }
      };

      SearchInputView.prototype.enableTypeahead = function(selector) {
        var eventDataset, fullDataset, serviceDataset;
        this.$searchEl = this.$el.find(selector);
        serviceDataset = {
          name: 'service',
          source: search.servicemapEngine.ttAdapter(),
          displayKey: function(c) {
            return c.name[p13n.getLanguage()];
          },
          templates: {
            suggestion: function(ctx) {
              return jade.template('typeahead-suggestion', ctx);
            }
          }
        };
        eventDataset = {
          name: 'event',
          source: search.linkedeventsEngine.ttAdapter(),
          displayKey: function(c) {
            return c.name[p13n.getLanguage()];
          },
          templates: {
            suggestion: function(ctx) {
              return jade.template('typeahead-suggestion', ctx);
            }
          }
        };
        fullDataset = {
          name: 'header',
          source: function(q, c) {
            return c([
              {
                query: q,
                object_type: 'query'
              }
            ]);
          },
          displayKey: function(s) {
            return s.query;
          },
          name: 'full',
          templates: {
            suggestion: function(s) {
              return jade.template('typeahead-fulltext', s);
            }
          }
        };
        this.geocoderBackend = new geocoding.GeocoderSourceBackend();
        this.$searchEl.typeahead({
          hint: false
        }, [fullDataset, this.geocoderBackend.getDatasetOptions(), serviceDataset, eventDataset]);
        return this.geocoderBackend.setOptions({
          $inputEl: this.$searchEl,
          selectionCallback: function(ev, data) {
            return app.commands.execute('selectPosition', data);
          }
        });
      };

      SearchInputView.prototype.getQuery = function() {
        return $.trim(this.$searchEl.val());
      };

      SearchInputView.prototype.executeQuery = function() {
        this.geocoderBackend.street = null;
        this.$searchEl.typeahead('close');
        return app.commands.execute('search', this.getInputText());
      };

      SearchInputView.prototype.autosuggestShowDetails = function(ev, data, _) {
        var model, objectType;
        model = null;
        objectType = data.object_type;
        if (objectType === 'address') {
          return;
        }
        this.$searchEl.typeahead('val', '');
        app.commands.execute('clearSearchResults', {
          navigate: false
        });
        $('.search-container input').val('');
        this.$searchEl.typeahead('close');
        switch (objectType) {
          case 'unit':
            model = new models.Unit(data);
            return app.commands.execute('selectUnit', model, {
              replace: true
            });
          case 'service':
            return app.commands.execute('addService', new models.Service(data));
          case 'event':
            return app.commands.execute('selectEvent', new models.Event(data));
          case 'query':
            return app.commands.execute('search', data.query);
        }
      };

      return SearchInputView;

    })(base.SMItemView);
  });

}).call(this);

//# sourceMappingURL=search-input.js.map
