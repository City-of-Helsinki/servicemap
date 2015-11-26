(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['cs!app/p13n', 'cs!app/views/base', 'cs!app/views/accessibility-personalisation'], function(p13n, base, AccessibilityPersonalisationView) {
    var PersonalisationView;
    return PersonalisationView = (function(_super) {
      __extends(PersonalisationView, _super);

      function PersonalisationView() {
        this.setMaxHeight = __bind(this.setMaxHeight, this);
        return PersonalisationView.__super__.constructor.apply(this, arguments);
      }

      PersonalisationView.prototype.className = 'personalisation-container';

      PersonalisationView.prototype.template = 'personalisation';

      PersonalisationView.prototype.regions = {
        accessibility: '#accessibility-personalisation'
      };

      PersonalisationView.prototype.events = function() {
        return {
          'click .personalisation-button': 'personalisationButtonClick',
          'keydown .personalisation-button': this.keyboardHandler(this.personalisationButtonClick, ['space', 'enter']),
          'click .ok-button': 'toggleMenu',
          'keydown .ok-button': this.keyboardHandler(this.toggleMenu, ['space']),
          'click .select-on-map': 'selectOnMap',
          'click .personalisations a': 'switchPersonalisation',
          'keydown .personalisations a': this.keyboardHandler(this.switchPersonalisation, ['space']),
          'click .personalisation-message a': 'openMenuFromMessage',
          'click .personalisation-message .close-button': 'closeMessage'
        };
      };

      PersonalisationView.prototype.personalisationIcons = {
        'city': ['helsinki', 'espoo', 'vantaa', 'kauniainen'],
        'senses': ['hearing_aid', 'visually_impaired', 'colour_blind'],
        'mobility': ['wheelchair', 'reduced_mobility', 'rollator', 'stroller']
      };

      PersonalisationView.prototype.initialize = function() {
        $(window).resize(this.setMaxHeight);
        this.listenTo(p13n, 'change', function() {
          this.setActivations();
          return this.renderIconsForSelectedModes();
        });
        return this.listenTo(p13n, 'user:open', function() {
          return this.personalisationButtonClick();
        });
      };

      PersonalisationView.prototype.personalisationButtonClick = function(ev) {
        if (ev != null) {
          ev.preventDefault();
        }
        if (!$('#personalisation').hasClass('open')) {
          return this.toggleMenu(ev);
        }
      };

      PersonalisationView.prototype.toggleMenu = function(ev) {
        if (ev != null) {
          ev.preventDefault();
        }
        return $('#personalisation').toggleClass('open');
      };

      PersonalisationView.prototype.openMenuFromMessage = function(ev) {
        if (ev != null) {
          ev.preventDefault();
        }
        this.toggleMenu();
        return this.closeMessage();
      };

      PersonalisationView.prototype.closeMessage = function(ev) {
        return this.$('.personalisation-message').removeClass('open');
      };

      PersonalisationView.prototype.selectOnMap = function(ev) {
        return ev.preventDefault();
      };

      PersonalisationView.prototype.renderIconsForSelectedModes = function() {
        var $container, $icon, group, iconClass, type, types, _ref, _results;
        $container = this.$('.selected-personalisations').empty();
        _ref = this.personalisationIcons;
        _results = [];
        for (group in _ref) {
          types = _ref[group];
          _results.push((function() {
            var _i, _len, _results1;
            _results1 = [];
            for (_i = 0, _len = types.length; _i < _len; _i++) {
              type = types[_i];
              if (this.modeIsActivated(type, group)) {
                if (group === 'city') {
                  iconClass = 'icon-icon-coat-of-arms-' + type.split('_').join('-');
                } else {
                  iconClass = 'icon-icon-' + type.split('_').join('-');
                }
                $icon = $("<span class='" + iconClass + "'></span>");
                _results1.push($container.append($icon));
              } else {
                _results1.push(void 0);
              }
            }
            return _results1;
          }).call(this));
        }
        return _results;
      };

      PersonalisationView.prototype.modeIsActivated = function(type, group) {
        var activated;
        activated = false;
        if (group === 'city') {
          activated = p13n.get('city') === type;
        } else if (group === 'mobility') {
          activated = p13n.getAccessibilityMode('mobility') === type;
        } else {
          activated = p13n.getAccessibilityMode(type);
        }
        return activated;
      };

      PersonalisationView.prototype.setActivations = function() {
        var $list;
        $list = this.$el.find('.personalisations');
        return $list.find('li').each((function(_this) {
          return function(idx, li) {
            var $button, $li, activated, group, type;
            $li = $(li);
            type = $li.data('type');
            group = $li.data('group');
            $button = $li.find('a[role="button"]');
            activated = _this.modeIsActivated(type, group);
            if (activated) {
              $li.addClass('selected');
            } else {
              $li.removeClass('selected');
            }
            return $button.attr('aria-pressed', activated);
          };
        })(this));
      };

      PersonalisationView.prototype.switchPersonalisation = function(ev) {
        var currentBackground, group, modeIsSet, newBackground, parentLi, type;
        ev.preventDefault();
        parentLi = $(ev.target).closest('li');
        group = parentLi.data('group');
        type = parentLi.data('type');
        if (group === 'mobility') {
          return p13n.toggleMobility(type);
        } else if (group === 'senses') {
          modeIsSet = p13n.toggleAccessibilityMode(type);
          currentBackground = p13n.get('map_background_layer');
          if (type === 'visually_impaired' || type === 'colour_blind') {
            newBackground = null;
            if (modeIsSet) {
              newBackground = 'accessible_map';
            } else if (currentBackground === 'accessible_map') {
              newBackground = 'servicemap';
            }
            if (newBackground) {
              return p13n.setMapBackgroundLayer(newBackground);
            }
          }
        } else if (group === 'city') {
          return p13n.toggleCity(type);
        }
      };

      PersonalisationView.prototype.render = function(opts) {
        PersonalisationView.__super__.render.call(this, opts);
        this.renderIconsForSelectedModes();
        return this.setActivations();
      };

      PersonalisationView.prototype.onRender = function() {
        this.accessibility.show(new AccessibilityPersonalisationView([]));
        return this.setMaxHeight();
      };

      PersonalisationView.prototype.setMaxHeight = function() {
        var maxHeight, offset, personalisationHeaderHeight, windowWidth;
        personalisationHeaderHeight = 56;
        windowWidth = $(window).width();
        offset = 0;
        if (windowWidth >= appSettings.mobile_ui_breakpoint) {
          offset = $('#personalisation').offset().top;
        }
        maxHeight = $(window).innerHeight() - personalisationHeaderHeight - offset;
        return this.$el.find('.personalisation-content').css({
          'max-height': maxHeight
        });
      };

      return PersonalisationView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=personalisation.js.map
