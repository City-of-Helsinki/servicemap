define (require) ->
    _                                = require 'underscore'
    {t}                              = require 'i18next'

    base                             = require 'cs!app/views/base'
    jade                             = require 'cs!app/jade'
    AccessibilityPersonalisationView = require 'cs!app/views/accessibility-personalisation'

    class FeedbackFormView extends base.SMLayout
        getTemplate: ->
            if @opts?.internalFeedback
                @template = 'feedback-form'
            else
                @template = 'unit-feedback-form'
            jade.getTemplate @template

        className: 'content modal-dialog'
        regions:
            accessibility: '#accessibility-section'
        events:
            'submit': '_submit'
            'change input[type=checkbox]': '_onCheckboxChanged'
            'change input[type=radio]': '_onRadioButtonChanged'
            'click .personalisations li': '_onPersonalisationClick'
            'blur input[type=text]': '_onFormInputBlur'
            'blur input[type=email]': '_onFormInputBlur'
            'blur textarea': '_onFormInputBlur'

        initialize: ({@unit, @model, @opts}) ->

        onShow: ->
            if @unit
                viewPoints = @model.get('accessibility_viewpoints') or []
                @accessibility.show new AccessibilityPersonalisationView({activeModes: viewPoints})

        onDomRefresh: ->
            @_adaptInputWidths @$el, 'input[type=text]'

        serializeData: ->
            keys = [
                'title', 'first_name', 'description',
                'email', 'accessibility_viewpoints',
                'can_be_published', 'service_request_type'
            ]
            value = (key) => @model.get(key) or ''
            values = _.object keys, _(keys).map(value)
            values.accessibility_enabled = @model.get('accessibility_enabled') or false
            values.email_enabled = @model.get('email_enabled') or false
            values.can_be_published = @model.get('can_be_published') or false
            if @unit
                values.unit = @unit.toJSON()
            values

        _adaptInputWidths: ($el, selector) ->
            _.defer =>
                $el.find(selector).each ->
                    pos = $(@).position().left
                    width = 440
                    width -= pos
                    $(@).css 'width', "#{width}px"
                $el.find('textarea').each -> $(@).css 'width', "460px"

        _submit: (ev) ->
            ev.preventDefault()
            if @unit?
                @model.set 'unit', @unit
            @model.save()

        _onCheckboxChanged: (ev) ->
            target = ev.currentTarget
            checked = target.checked
            $hiddenSection = $(target).closest('.form-section').find('.hidden-section')
            if checked
                $hiddenSection.removeClass 'hidden'
                @_adaptInputWidths $hiddenSection, 'input[type=email]'
            else
                $hiddenSection.addClass 'hidden'
            @_setModelField @_getModelFieldId($(target)), checked

        _onRadioButtonChanged: (ev) ->
            $target = $(ev.currentTarget)
            name = $target.attr 'name'
            value = $target.val()
            @model.set @_getModelFieldId($target, attrName='name'), value

        _onFormInputBlur: (ev) ->
            $target = $ ev.currentTarget
            contents = $target.val()
            id = @_getModelFieldId $target
            success = @_setModelField id, contents
            $container = $target.closest('.form-section').find('.validation-error')
            if success
                $container.addClass 'hidden'
            else
                error = @model.validationError
                $container.html t("feedback.form.validation.#{error[id]}")
                $container.removeClass 'hidden'

        _getModelFieldId: ($target, attrName='id') ->
            try
                $target.attr(attrName).replace /open311-/, ''
            catch TypeError
                null

        _setModelField: (id, val) ->
            @model.set id, val, validate: true

        _onPersonalisationClick: (ev) ->
            $target = $(ev.currentTarget)
            type = $target.data 'type'
            $target.closest('#accessibility-section').find('li').removeClass 'selected'
            $target.addClass 'selected'
            @model.set 'accessibility_viewpoints', [type]
