define [
    'underscore',
    'app/views/base',
    'app/views/accessibility-personalisation',
], (
    _,
    base,
    AccessibilityPersonalisationView
) ->

    class FeedbackFormView extends base.SMLayout
        template: 'feedback-form'
        className: 'content modal-dialog'
        regions:
            accessibility: '#accessibility-section'
        events:
            'submit': '_onSubmit'
            'change input[type=checkbox]': '_onCheckboxChanged'
            'click .personalisations li': '_onPersonalisationClick'

        onRender: ->
            @_adaptInputWidths @$el, 'input[type=text]'
            @accessibility.show new AccessibilityPersonalisationView

        serializeData: ->
            unit: @model.toJSON()

        _adaptInputWidths: ($el, selector) ->
            _.defer =>
                $el.find(selector).each ->
                    pos = $(@).position().left
                    width = 440
                    width -= pos
                    $(@).css 'width', "#{width}px"
                $el.find('textarea').each -> $(@).css 'width', "460px"

        _onSubmit: (ev) ->
            ev.preventDefault()

        _onCheckboxChanged: (ev) ->
            target = ev.currentTarget
            checked = target.checked
            $hiddenSection = $(target).closest('.form-section').find('.hidden-section')
            if checked
                $hiddenSection.removeClass 'hidden'
                @_adaptInputWidths $hiddenSection, 'input[type=email]'
            else
                $hiddenSection.addClass 'hidden'

        _serviceCodeFromPersonalisation: (type) ->
            switch type
                when 'hearing_aid'
                    10
                when 'visually_impaired'
                    20
                when 'colour_blind'
                    30
                when 'wheelchair'
                    40
                when 'reduced_mobility'
                    50
                when 'rollator'
                    60
                when 'stroller'
                    70

        _onPersonalisationClick: (ev) ->
            $target = $(ev.currentTarget)
            type = $target.data 'type'
            $target.closest('#accessibility-section').find('li').removeClass 'selected'
            $target.addClass 'selected'
            @serviceCode = @_serviceCodeFromPersonalisation(type)
