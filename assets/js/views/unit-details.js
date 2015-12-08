(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(['i18next', 'harvey', 'cs!app/p13n', 'cs!app/dateformat', 'cs!app/draw', 'cs!app/map-view', 'cs!app/views/base', 'cs!app/views/route', 'cs!app/views/accessibility'], function(i18n, _harvey, p13n, dateformat, draw, MapView, base, RouteView, _arg) {
    var AccessibilityDetailsView, EventListRowView, EventListView, FeedbackItemView, FeedbackListView, UnitDetailsView;
    AccessibilityDetailsView = _arg.AccessibilityDetailsView;
    UnitDetailsView = (function(_super) {
      __extends(UnitDetailsView, _super);

      function UnitDetailsView() {
        this.updateEventsUi = __bind(this.updateEventsUi, this);
        return UnitDetailsView.__super__.constructor.apply(this, arguments);
      }

      UnitDetailsView.prototype.id = 'details-view-container';

      UnitDetailsView.prototype.className = 'navigation-element';

      UnitDetailsView.prototype.template = 'details';

      UnitDetailsView.prototype.regions = {
        'routeRegion': '.section.route-section',
        'accessibilityRegion': '.section.accessibility-section',
        'eventsRegion': '.event-list',
        'feedbackRegion': '.feedback-list'
      };

      UnitDetailsView.prototype.events = {
        'click .back-button': 'userClose',
        'click .icon-icon-close': 'userClose',
        'click .map-active-area': 'showMap',
        'click .show-map': 'showMap',
        'click .mobile-header': 'showContent',
        'click .show-more-events': 'showMoreEvents',
        'click .disabled': 'preventDisabledClick',
        'click .set-accessibility-profile': 'openAccessibilityMenu',
        'click .leave-feedback': 'leaveFeedbackOnAccessibility',
        'click .section.main-info .description .body-expander': 'toggleDescriptionBody',
        'show.bs.collapse': 'scrollToExpandedSection',
        'click .send-feedback': '_onClickSendFeedback'
      };

      UnitDetailsView.prototype.type = 'details';

      UnitDetailsView.prototype.initialize = function(options) {
        this.INITIAL_NUMBER_OF_EVENTS = 5;
        this.NUMBER_OF_EVENTS_FETCHED = 20;
        this.embedded = options.embedded;
        this.searchResults = options.searchResults;
        this.selectedUnits = options.selectedUnits;
        this.selectedPosition = options.selectedPosition;
        this.routingParameters = options.routingParameters;
        this.route = options.route;
        return this.listenTo(this.searchResults, 'reset', this.render);
      };

      UnitDetailsView.prototype._$getMobileHeader = function() {
        return this.$el.find('.mobile-header');
      };

      UnitDetailsView.prototype._$getDefaultHeader = function() {
        return this.$el.find('.content .main-info .header');
      };

      UnitDetailsView.prototype._hideHeader = function($header) {
        return $header.attr('aria-hidden', 'true');
      };

      UnitDetailsView.prototype._showHeader = function($header) {
        return $header.removeAttr('aria-hidden');
      };

      UnitDetailsView.prototype._attachMobileHeaderListeners = function() {
        Harvey.attach('(max-width:767px)', {
          on: (function(_this) {
            return function() {
              _this._hideHeader(_this._$getDefaultHeader());
              return _this._showHeader(_this._$getMobileHeader());
            };
          })(this)
        });
        return Harvey.attach('(min-width:768px)', {
          on: (function(_this) {
            return function() {
              _this._hideHeader(_this._$getMobileHeader());
              return _this._showHeader(_this._$getDefaultHeader());
            };
          })(this)
        });
      };

      UnitDetailsView.prototype._onClickSendFeedback = function(ev) {
        return app.commands.execute('composeFeedback', this.model);
      };

      UnitDetailsView.prototype.onRender = function() {
        var color, context, contextMobile, id, marker, markerCanvas, markerCanvasMobile, rotation, size;
        if (this.model.eventList.isEmpty()) {
          this.listenTo(this.model.eventList, 'reset', (function(_this) {
            return function(list) {
              _this.updateEventsUi(list.fetchState);
              return _this.renderEvents(list);
            };
          })(this));
          this.model.eventList.pageSize = this.INITIAL_NUMBER_OF_EVENTS;
          this.model.getEvents();
          this.model.eventList.pageSize = this.NUMBER_OF_EVENTS_FETCHED;
          this.model.getFeedback();
        } else {
          this.updateEventsUi(this.model.eventList.fetchState);
          this.renderEvents(this.model.eventList);
        }
        if (this.model.feedbackList.isEmpty()) {
          this.listenTo(this.model.feedbackList, 'reset', (function(_this) {
            return function(list) {
              return _this.renderFeedback(_this.model.feedbackList);
            };
          })(this));
        } else {
          this.renderFeedback(this.model.feedbackList);
        }
        this.accessibilityRegion.show(new AccessibilityDetailsView({
          model: this.model
        }));
        this.routeRegion.show(new RouteView({
          model: this.model,
          route: this.route,
          parentView: this,
          routingParameters: this.routingParameters,
          selectedUnits: this.selectedUnits,
          selectedPosition: this.selectedPosition
        }));
        app.vent.trigger('site-title:change', this.model.get('name'));
        this._attachMobileHeaderListeners();
        markerCanvas = this.$el.find('#details-marker-canvas').get(0);
        markerCanvasMobile = this.$el.find('#details-marker-canvas-mobile').get(0);
        context = markerCanvas.getContext('2d');
        contextMobile = markerCanvasMobile.getContext('2d');
        size = 40;
        color = app.colorMatcher.unitColor(this.model) || 'rgb(0, 0, 0)';
        id = 0;
        rotation = 90;
        marker = new draw.Plant(size, color, id, rotation);
        marker.draw(context);
        marker.draw(contextMobile);
        return _.defer((function(_this) {
          return function() {
            return _this.$el.find('a').first().focus();
          };
        })(this));
      };

      UnitDetailsView.prototype.updateEventsUi = function(fetchState) {
        var $eventsSection, shortText, _ref;
        $eventsSection = this.$el.find('.events-section');
        if (fetchState.count) {
          shortText = i18n.t('sidebar.event_count', {
            count: fetchState.count
          });
        } else {
          shortText = i18n.t('sidebar.no_events');
          this.$('.show-more-events').hide();
          $eventsSection.find('.collapser').addClass('disabled');
        }
        $eventsSection.find('.short-text').text(shortText);
        if (!fetchState.next && this.model.eventList.length === ((_ref = this.eventsRegion.currentView) != null ? _ref.collection.length : void 0)) {
          return this.$('.show-more-events').hide();
        }
      };

      UnitDetailsView.prototype.userClose = function(event) {
        event.stopPropagation();
        app.commands.execute('clearSelectedUnit');
        if (!this.searchResults.isEmpty()) {
          app.commands.execute('search', this.searchResults.query);
        }
        return this.trigger('user:close');
      };

      UnitDetailsView.prototype.preventDisabledClick = function(event) {
        event.preventDefault();
        return event.stopPropagation();
      };

      UnitDetailsView.prototype.showMap = function(event) {
        event.preventDefault();
        this.$el.addClass('minimized');
        return MapView.setMapActiveAreaMaxHeight({
          maximize: true
        });
      };

      UnitDetailsView.prototype.showContent = function(event) {
        event.preventDefault();
        this.$el.removeClass('minimized');
        return MapView.setMapActiveAreaMaxHeight({
          maximize: false
        });
      };

      UnitDetailsView.prototype.getTranslatedProvider = function(providerType) {
        var SUPPORTED_PROVIDER_TYPES;
        SUPPORTED_PROVIDER_TYPES = [101, 102, 103, 104, 105];
        if (__indexOf.call(SUPPORTED_PROVIDER_TYPES, providerType) >= 0) {
          return i18n.t("sidebar.provider_type." + providerType);
        } else {
          return '';
        }
      };

      UnitDetailsView.prototype.serializeData = function() {
        var MAX_LENGTH, data, description, embedded, words;
        embedded = this.embedded;
        data = this.model.toJSON();
        data.provider = this.getTranslatedProvider(this.model.get('provider_type'));
        if (!this.searchResults.isEmpty()) {
          data.back_to = i18n.t('sidebar.back_to.search');
        }
        MAX_LENGTH = 20;
        description = data.description;
        if (description) {
          words = description.split(/[ ]+/);
          if (words.length > MAX_LENGTH + 1) {
            data.description_ingress = words.slice(0, MAX_LENGTH).join(' ');
            data.description_body = words.slice(MAX_LENGTH).join(' ');
          } else {
            data.description_ingress = description;
          }
        }
        data.embedded_mode = embedded;
        data.feedback_count = this.model.feedbackList.length;
        return data;
      };

      UnitDetailsView.prototype.renderEvents = function(events) {
        if (events != null) {
          if (!events.isEmpty()) {
            this.$el.find('.section.events-section').removeClass('hidden');
            return this.eventsRegion.show(new EventListView({
              collection: events
            }));
          }
        }
      };

      UnitDetailsView.prototype._feedbackSummary = function(feedbackItems) {
        var count;
        count = feedbackItems.size();
        if (count) {
          return i18n.t('feedback.count', {
            count: count
          });
        } else {
          return '';
        }
      };

      UnitDetailsView.prototype.renderFeedback = function(feedbackItems) {
        var $feedbackSection, feedbackSummary;
        if (this.model.get('organization') !== 91) {
          return;
        }
        if (feedbackItems != null) {
          feedbackItems.unit = this.model;
          feedbackSummary = this._feedbackSummary(feedbackItems);
          $feedbackSection = this.$el.find('.feedback-section');
          $feedbackSection.find('.short-text').text(feedbackSummary);
          $feedbackSection.find('.feedback-count').text(feedbackSummary);
          return this.feedbackRegion.show(new FeedbackListView({
            collection: feedbackItems
          }));
        }
      };

      UnitDetailsView.prototype.showMoreEvents = function(event) {
        var options;
        event.preventDefault();
        options = {
          spinnerOptions: {
            container: this.$('.show-more-events').get(0),
            hideContainerContent: true
          }
        };
        if (this.model.eventList.length <= this.INITIAL_NUMBER_OF_EVENTS) {
          return this.model.getEvents({}, options);
        } else {
          options.success = (function(_this) {
            return function() {
              return _this.updateEventsUi(_this.model.eventList.fetchState);
            };
          })(this);
          return this.model.eventList.fetchNext(options);
        }
      };

      UnitDetailsView.prototype.toggleDescriptionBody = function(ev) {
        var $target;
        $target = $(ev.currentTarget);
        $target.toggle();
        return $target.closest('.description').find('.body').toggle();
      };

      UnitDetailsView.prototype.scrollToExpandedSection = function(event) {
        var $container, $section, scrollTo;
        $container = this.$el.find('.content').first();
        if ($(event.target).hasClass('steps')) {
          return;
        }
        $section = $(event.target).closest('.section');
        scrollTo = $container.scrollTop() + $section.position().top;
        return $('#details-view-container .content').animate({
          scrollTop: scrollTo
        });
      };

      UnitDetailsView.prototype.openAccessibilityMenu = function(event) {
        event.preventDefault();
        return p13n.trigger('user:open');
      };

      return UnitDetailsView;

    })(base.SMLayout);
    EventListRowView = (function(_super) {
      __extends(EventListRowView, _super);

      function EventListRowView() {
        return EventListRowView.__super__.constructor.apply(this, arguments);
      }

      EventListRowView.prototype.tagName = 'li';

      EventListRowView.prototype.template = 'event-list-row';

      EventListRowView.prototype.events = {
        'click .show-event-details': 'showEventDetails'
      };

      EventListRowView.prototype.serializeData = function() {
        var endTime, formattedDatetime, startTime;
        startTime = this.model.get('start_time');
        endTime = this.model.get('end_time');
        formattedDatetime = dateformat.humanizeEventDatetime(startTime, endTime, 'small');
        return {
          name: p13n.getTranslatedAttr(this.model.get('name')),
          datetime: formattedDatetime,
          info_url: p13n.getTranslatedAttr(this.model.get('info_url'))
        };
      };

      EventListRowView.prototype.showEventDetails = function(event) {
        event.preventDefault();
        return app.commands.execute('selectEvent', this.model);
      };

      return EventListRowView;

    })(base.SMItemView);
    EventListView = (function(_super) {
      __extends(EventListView, _super);

      function EventListView() {
        return EventListView.__super__.constructor.apply(this, arguments);
      }

      EventListView.prototype.tagName = 'ul';

      EventListView.prototype.className = 'events';

      EventListView.prototype.itemView = EventListRowView;

      EventListView.prototype.initialize = function(opts) {
        return this.parent = opts.parent;
      };

      return EventListView;

    })(base.SMCollectionView);
    FeedbackItemView = (function(_super) {
      __extends(FeedbackItemView, _super);

      function FeedbackItemView() {
        return FeedbackItemView.__super__.constructor.apply(this, arguments);
      }

      FeedbackItemView.prototype.tagName = 'li';

      FeedbackItemView.prototype.template = 'feedback-list-row';

      FeedbackItemView.prototype.initialize = function(options) {
        return this.unit = options.unit;
      };

      FeedbackItemView.prototype.serializeData = function() {
        var data;
        data = FeedbackItemView.__super__.serializeData.call(this);
        data.unit = this.unit.toJSON();
        return data;
      };

      return FeedbackItemView;

    })(base.SMItemView);
    FeedbackListView = (function(_super) {
      __extends(FeedbackListView, _super);

      function FeedbackListView() {
        return FeedbackListView.__super__.constructor.apply(this, arguments);
      }

      FeedbackListView.prototype.tagName = 'ul';

      FeedbackListView.prototype.className = 'feedback';

      FeedbackListView.prototype.itemView = FeedbackItemView;

      FeedbackListView.prototype.itemViewOptions = function() {
        return {
          unit: this.collection.unit
        };
      };

      return FeedbackListView;

    })(base.SMCollectionView);
    return UnitDetailsView;
  });

}).call(this);

//# sourceMappingURL=unit-details.js.map
