(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'i18next', 'moment', 'cs!app/accessibility', 'cs!app/accessibility-sentences', 'cs!app/p13n', 'cs!app/views/base'], function(_, i18n, moment, accessibility, accessibilitySentences, p13n, base) {
    var AccessibilityDetailsView, AccessibilityViewpointView;
    AccessibilityViewpointView = (function(_super) {
      __extends(AccessibilityViewpointView, _super);

      function AccessibilityViewpointView() {
        return AccessibilityViewpointView.__super__.constructor.apply(this, arguments);
      }

      AccessibilityViewpointView.prototype.template = 'accessibility-viewpoint-summary';

      AccessibilityViewpointView.prototype.initialize = function(opts) {
        this.filterTransit = (opts != null ? opts.filterTransit : void 0) || false;
        return this.template = this.options.template || this.template;
      };

      AccessibilityViewpointView.prototype.serializeData = function() {
        var profiles;
        profiles = p13n.getAccessibilityProfileIds(this.filterTransit);
        return {
          profile_set: _.keys(profiles).length,
          profiles: p13n.getProfileElements(profiles)
        };
      };

      return AccessibilityViewpointView;

    })(base.SMItemView);
    AccessibilityDetailsView = (function(_super) {
      __extends(AccessibilityDetailsView, _super);

      function AccessibilityDetailsView() {
        return AccessibilityDetailsView.__super__.constructor.apply(this, arguments);
      }

      AccessibilityDetailsView.prototype.className = 'unit-accessibility-details';

      AccessibilityDetailsView.prototype.template = 'unit-accessibility-details';

      AccessibilityDetailsView.prototype.regions = {
        'viewpointRegion': '.accessibility-viewpoint'
      };

      AccessibilityDetailsView.prototype.events = {
        'click #accessibility-collapser': 'toggleCollapse'
      };

      AccessibilityDetailsView.prototype.toggleCollapse = function() {
        this.collapsed = !this.collapsed;
        return true;
      };

      AccessibilityDetailsView.prototype.initialize = function() {
        this.listenTo(p13n, 'change', this.render);
        this.listenTo(accessibility, 'change', this.render);
        this.collapsed = true;
        this.accessibilitySentences = {};
        return accessibilitySentences.fetch({
          id: this.model.id
        }, (function(_this) {
          return function(data) {
            _this.accessibilitySentences = data;
            return _this.render();
          };
        })(this));
      };

      AccessibilityDetailsView.prototype.onRender = function() {
        if (this.model.hasAccessibilityData()) {
          return this.viewpointRegion.show(new AccessibilityViewpointView());
        }
      };

      AccessibilityDetailsView.prototype._calculateSentences = function() {
        return _.object(_.map(this.accessibilitySentences.sentences, (function(_this) {
          return function(sentences, groupId) {
            return [
              p13n.getTranslatedAttr(_this.accessibilitySentences.groups[groupId]), _.map(sentences, function(sentence) {
                return p13n.getTranslatedAttr(sentence);
              })
            ];
          };
        })(this)));
      };

      AccessibilityDetailsView.prototype.serializeData = function() {
        var collapseClasses, details, group, groups, hasData, headerClasses, iconClass, profileSet, profiles, sentenceError, sentenceGroups, shortText, shortcomings, shortcomingsCount, shortcomingsPending, status, __, _ref;
        hasData = this.model.hasAccessibilityData();
        shortcomingsPending = false;
        profiles = p13n.getAccessibilityProfileIds();
        if (_.keys(profiles).length) {
          profileSet = true;
        } else {
          profileSet = false;
          profiles = p13n.getAllAccessibilityProfileIds();
        }
        if (hasData) {
          _ref = this.model.getTranslatedShortcomings(), status = _ref.status, shortcomings = _ref.results;
          shortcomingsPending = status === 'pending';
        } else {
          shortcomings = {};
        }
        shortcomingsCount = 0;
        for (__ in shortcomings) {
          group = shortcomings[__];
          shortcomingsCount += _.values(group).length;
        }
        sentenceGroups = [];
        details = [];
        if ('error' in this.accessibilitySentences) {
          details = null;
          sentenceGroups = null;
          sentenceError = true;
        } else {
          details = this._calculateSentences();
          sentenceGroups = _.map(_.values(this.accessibilitySentences.groups), function(v) {
            return p13n.getTranslatedAttr(v);
          });
          sentenceError = false;
        }
        collapseClasses = [];
        headerClasses = [];
        if (this.collapsed) {
          headerClasses.push('collapsed');
        } else {
          collapseClasses.push('in');
        }
        shortText = '';
        if (_.keys(profiles).length) {
          if (hasData) {
            if (shortcomingsCount) {
              if (profileSet) {
                headerClasses.push('has-shortcomings');
                shortText = i18n.t('accessibility.shortcoming_count', {
                  count: shortcomingsCount
                });
              }
            } else {
              if (shortcomingsPending) {
                headerClasses.push('shortcomings-pending');
                shortText = i18n.t('accessibility.pending');
              } else if (profileSet) {
                headerClasses.push('no-shortcomings');
                shortText = i18n.t('accessibility.no_shortcomings');
              }
            }
          } else {
            groups = this.accessibilitySentences.groups;
            if (!((groups != null) && _(groups).keys().length > 0)) {
              shortText = i18n.t('accessibility.no_data');
            }
          }
        }
        iconClass = profileSet ? p13n.getProfileElements(profiles).pop()['icon'] : 'icon-icon-wheelchair';
        return {
          has_data: hasData,
          profile_set: profileSet,
          icon_class: iconClass,
          shortcomings_pending: shortcomingsPending,
          shortcomings_count: shortcomingsCount,
          shortcomings: shortcomings,
          groups: sentenceGroups,
          details: details,
          sentence_error: sentenceError,
          header_classes: headerClasses.join(' '),
          collapse_classes: collapseClasses.join(' '),
          short_text: shortText,
          feedback: this.getDummyFeedback()
        };
      };

      AccessibilityDetailsView.prototype.getDummyFeedback = function() {
        var feedback, lastMonth, now, yesterday;
        now = new Date();
        yesterday = new Date(now.setDate(now.getDate() - 1));
        lastMonth = new Date(now.setMonth(now.getMonth() - 1));
        feedback = [];
        feedback.push({
          time: moment(yesterday).calendar(),
          profile: 'wheelchair user.',
          header: 'The ramp is too steep',
          content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
        });
        feedback.push({
          time: moment(lastMonth).calendar(),
          profile: 'rollator user',
          header: 'Not accessible at all and the staff are unhelpful!!!!',
          content: "The ramp is just bad! It's not connected to the entrance stand out clearly. Outside the door there is sufficient room for moving e.g. with a wheelchair. The door opens easily manually."
        });
        return feedback;
      };

      AccessibilityDetailsView.prototype.leaveFeedbackOnAccessibility = function(event) {
        return event.preventDefault();
      };

      return AccessibilityDetailsView;

    })(base.SMLayout);
    return {
      AccessibilityDetailsView: AccessibilityDetailsView,
      AccessibilityViewpointView: AccessibilityViewpointView
    };
  });

}).call(this);

//# sourceMappingURL=accessibility.js.map
