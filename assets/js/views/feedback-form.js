(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'cs!app/views/base', 'cs!app/views/accessibility-personalisation', 'i18next'], function(_, base, AccessibilityPersonalisationView, _arg) {
    var FeedbackFormView, t;
    t = _arg.t;
    return FeedbackFormView = (function(_super) {
      __extends(FeedbackFormView, _super);

      function FeedbackFormView() {
        return FeedbackFormView.__super__.constructor.apply(this, arguments);
      }

      FeedbackFormView.prototype.template = 'feedback-form';

      FeedbackFormView.prototype.className = 'content modal-dialog';

      FeedbackFormView.prototype.regions = {
        accessibility: '#accessibility-section'
      };

      FeedbackFormView.prototype.events = {
        'submit': '_submit',
        'change input[type=checkbox]': '_onCheckboxChanged',
        'change input[type=radio]': '_onRadioButtonChanged',
        'click .personalisations li': '_onPersonalisationClick',
        'blur input[type=text]': '_onFormInputBlur',
        'blur input[type=email]': '_onFormInputBlur',
        'blur textarea': '_onFormInputBlur'
      };

      FeedbackFormView.prototype.initialize = function(_arg1) {
        this.unit = _arg1.unit, this.model = _arg1.model;
      };

      FeedbackFormView.prototype.onRender = function() {
        this._adaptInputWidths(this.$el, 'input[type=text]');
        return this.accessibility.show(new AccessibilityPersonalisationView(this.model.get('accessibility_viewpoints') || []));
      };

      FeedbackFormView.prototype.serializeData = function() {
        var keys, value, values;
        keys = ['title', 'first_name', 'description', 'email', 'accessibility_viewpoints', 'can_be_published', 'service_request_type'];
        value = (function(_this) {
          return function(key) {
            return _this.model.get(key) || '';
          };
        })(this);
        values = _.object(keys, _(keys).map(value));
        values.accessibility_enabled = this.model.get('accessibility_enabled') || false;
        values.email_enabled = this.model.get('email_enabled') || false;
        values.unit = this.unit.toJSON();
        return values;
      };

      FeedbackFormView.prototype._adaptInputWidths = function($el, selector) {
        return _.defer((function(_this) {
          return function() {
            $el.find(selector).each(function() {
              var pos, width;
              pos = $(this).position().left;
              width = 440;
              width -= pos;
              return $(this).css('width', "" + width + "px");
            });
            return $el.find('textarea').each(function() {
              return $(this).css('width', "460px");
            });
          };
        })(this));
      };

      FeedbackFormView.prototype._submit = function(ev) {
        ev.preventDefault();
        this.model.set('unit', this.unit);
        return this.model.save();
      };

      FeedbackFormView.prototype._onCheckboxChanged = function(ev) {
        var $hiddenSection, checked, target;
        target = ev.currentTarget;
        checked = target.checked;
        $hiddenSection = $(target).closest('.form-section').find('.hidden-section');
        if (checked) {
          $hiddenSection.removeClass('hidden');
          this._adaptInputWidths($hiddenSection, 'input[type=email]');
        } else {
          $hiddenSection.addClass('hidden');
        }
        return this._setModelField(this._getModelFieldId($(target)), checked);
      };

      FeedbackFormView.prototype._onRadioButtonChanged = function(ev) {
        var $target, attrName, name, value;
        $target = $(ev.currentTarget);
        name = $target.attr('name');
        value = $target.val();
        return this.model.set(this._getModelFieldId($target, attrName = 'name'), value);
      };

      FeedbackFormView.prototype._onFormInputBlur = function(ev) {
        var $container, $target, contents, error, id, success;
        $target = $(ev.currentTarget);
        contents = $target.val();
        id = this._getModelFieldId($target);
        success = this._setModelField(id, contents);
        $container = $target.closest('.form-section').find('.validation-error');
        if (success) {
          return $container.addClass('hidden');
        } else {
          error = this.model.validationError;
          $container.html(t("feedback.form.validation." + error[id]));
          return $container.removeClass('hidden');
        }
      };

      FeedbackFormView.prototype._getModelFieldId = function($target, attrName) {
        var TypeError;
        if (attrName == null) {
          attrName = 'id';
        }
        try {
          return $target.attr(attrName).replace(/open311-/, '');
        } catch (_error) {
          TypeError = _error;
          return null;
        }
      };

      FeedbackFormView.prototype._setModelField = function(id, val) {
        return this.model.set(id, val, {
          validate: true
        });
      };

      FeedbackFormView.prototype._onPersonalisationClick = function(ev) {
        var $target, type;
        $target = $(ev.currentTarget);
        type = $target.data('type');
        $target.closest('#accessibility-section').find('li').removeClass('selected');
        $target.addClass('selected');
        return this.model.set('accessibility_viewpoints', [type]);
      };

      return FeedbackFormView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=feedback-form.js.map
