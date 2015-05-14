define [
    'underscore',
    'app/views/base',
], (
    _,
    base
) ->

    class AddressDialogView extends base.SMItemView
        className: 'address-dialog'
        template: 'address-dialog'
        events:
#            'keydown input.address-number': 'filterWhitespace'
            'keyup input.address-number': 'handleInputTwo'
        initialize: ->
            @street = @collection.first().get 'street'
            @collection = @collection.sortBy (x) =>
                parseInt(x.get('number'))
            @numbers = _(@collection).chain()
                .map (x) => x.get 'number'
                .map (x) => parseInt(x)
                .value()
            @numberParts = @collection.map (x) =>
                append = ''
                if x.get 'letter'
                    append = x.get('letter')
                else if x.get('number_end')
                    append = '-' + x.get('number_end')
                x.get('number') + append
            @range =
                max: _.max @numbers
                min: _.min @numbers

        serializeData: ->
            street: @street
            range: @range

        onRender: ->
            @$el.find('.address-error').hide()

        # filterWhitespace: (ev) ->
        #     char = String.fromCharCode ev.which
        #     if char.toLowerCase().search(/[a-z0-9]/) == -1
        #         ev.preventDefault()

        handleInputTwo: (ev) ->
            $input = @$el.find('input')
            $listEl = @$el.find('.address-results')
            $results = @$el.find('.address-results')
            $error = @$el.find('.address-error')

            value = $input.val()
            if ev.which == 13 # enter
                @trigger 'selection', value
                return
            @filteredNumberParts = _(@numberParts).filter (x) =>
                x.toLowerCase().indexOf(value.toLowerCase()) == 0
            if value.length == 0
                $listEl.html ''
                $results.addClass 'empty'
                return
            if @filteredNumberParts.length == 0
                @invalid = true
                $error.show()
            else
                @invalid = false
                contents = _(@filteredNumberParts.slice(0, 5))
                    .map (x) =>
                        "<li><a href=\"#\">#{x}</a></li>"
                $listEl.html contents
                $listEl.find('a').on 'click', (ev) =>
                    @trigger 'selection', $(ev.currentTarget).text()
            $results.removeClass 'empty'
            if @invalid
                $error.show()
                $input.addClass 'invalid'
                $input.removeClass 'valid'
            else
                $error.hide()
                $input.removeClass 'invalid'
                $input.addClass 'valid'
