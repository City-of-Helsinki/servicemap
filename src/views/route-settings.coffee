define (require) ->
    _                  = require 'underscore'
    moment             = require 'moment'
    datetimepicker     = require 'bootstrap-datetimepicker'

    p13n               = require 'cs!app/p13n'
    models             = require 'cs!app/models'
    base               = require 'cs!app/views/base'
    accessibilityViews = require 'cs!app/views/accessibility'
    geocoding          = require 'cs!app/geocoding'
    jade               = require 'cs!app/jade'
    CancelToken        = require 'cs!app/cancel-token'
    {LoadingIndicatorView} = require 'cs!app/views/loading-indicator'

    class RouteSettingsView extends base.SMLayout
        template: 'route-settings'
        regions:
            'endpointsRegion': '.route-endpoints'
            'headerRegion': '.route-settings-header'
            'routeControllersRegion': '.route-controllers'
            'accessibilitySummaryRegion': '.accessibility-viewpoint-part'
            'transportModeControlsRegion': '.transport_mode_controls'

        initialize: (attrs) ->
            @unit = attrs.unit
            @listenTo @model, 'change', @updateRegions

        onShow: ->
            @endpointsRegion.show new RouteEndpointsView
                model: @model
            @headerRegion.show new RouteSettingsHeaderView
            @routeControllersRegion.show new RouteControllersView
                model: @model
                unit: @unit
            @accessibilitySummaryRegion.show new accessibilityViews.AccessibilityViewpointView
                filterTransit: true
                template: 'accessibility-viewpoint-oneline'
            @transportModeControlsRegion.show new TransportModeControlsView

        updateRegions: ->
            @endpointsRegion.currentView.update()
            @headerRegion.currentView.render()
            @accessibilitySummaryRegion.currentView.render()
            @transportModeControlsRegion.currentView.render()

    class RouteEndpointsView extends base.SMLayout
        template: 'route-endpoints'
        regions:
            locationLoadingIndicator: '#location-loading-indicator'
        events:
            'click .detect-current-location': 'detectCurrentLocation'
            'click input': 'editInput'
            'click .swap-endpoints': 'swapEndpoints'
            'click .tt-suggestion': (e) ->
                e.stopPropagation()

        initialize: (attrs) ->
            @editing = false

        updateElements: ->
            # Show either location loading indicator or detect location link
            if @model.isDetectingLocation()
                @$el.find('#location-loading-indicator').removeClass('hidden')
                @$el.find('.current-location').addClass('hidden')
            else
                @$el.find('#location-loading-indicator').addClass('hidden')
                @$el.find('.current-location').removeClass('hidden')

            # Update inputs values
            @_getOriginInput().val @_getOriginInputText()
            @_getDestinationInput().val @_getDestinationInputText()

            # Lock the other one of the inputs
            if @model.getOriginLocked()
                @lockInput @$el.find('.origin-input')
                @unlockInput @$el.find('.destination-input')
            else
                @lockInput @$el.find('.destination-input')
                @unlockInput @$el.find('.origin-input')

            # If current location selected, no need to make detect location
            # action clickable
            if @model.hasDetectedLocation()
                @$el.find(".detect-current-location").addClass("disabled")
            else
                @$el.find(".detect-current-location").removeClass("disabled")

        unlockInput: (input) ->
            input.attr("disabled", false)
            input.removeClass("locked")
            input.addClass("unlocked")

        lockInput: (input) ->
            input.attr("disabled", true)
            input.addClass("locked")
            input.removeClass("unlocked")

        update: ->
            @showLocationLoading()
            @updateElements()

        showLocationLoading: ->
            @cancelToken = new CancelToken()
            @cancelToken.set 'status', 'fetching.location'
            @locationLoadingIndicator?.show new LoadingIndicatorView(model: @cancelToken)

        onShow: ->
            @update()

        onDomRefresh: ->
            @enableTypeahead '.transit-start input'
            @enableTypeahead '.transit-end input'

        applyChanges: ->
            @editing = false
            @update()
            @model.triggerComplete()

        enableTypeahead: (selector) ->
            $input = @$el.find selector

            unless $input.length
                return

            geocoderBackend = new geocoding.GeocoderSourceBackend()
            options = geocoderBackend.getDatasetOptions()
            options.templates.empty = (ctx) -> jade.template 'typeahead-no-results', ctx
            $input.typeahead null, [options]

            selectAddress = (event, match) =>
                @commit = true
                switch $(event.currentTarget).attr 'data-endpoint'
                    when 'origin'
                        @model.setOrigin match
                    when 'destination'
                        @model.setDestination match
                @applyChanges()
                $(event.currentTarget).blur()

            geocoderBackend.setOptions
                $inputEl: $input
                selectionCallback: selectAddress

        _locationName: (object) =>
            @model.getEndpointName object

        _locationShortName: (object) =>
            if object.object_type == 'address'
                object.humanAddress exclude: municipality: true
            else
                @model.getEndpointName object

        _getInputText: (model, input, locked) ->
            longModelName = @_locationName model
            shortModelName = @_locationShortName model
            inputValue = $.trim input?.val()

            if !@editing or locked
                longModelName
            else
                # if we are currently showing 'Current position' for the user and we don't
                # want her to have that string for editing
                if inputValue == longModelName and model instanceof models.CoordinatePosition
                    return ''
                # When user edits an address, give the shorter version to make it more easy
                else if inputValue == longModelName
                    shortModelName
                else
                    inputValue

        _getOriginInput: ->
            @$el.find '.transit-start input.tt-input'
        _getDestinationInput: ->
            @$el.find '.transit-end input.tt-input'

        _getOriginInputText: =>
            @_getInputText @model.getOrigin(), @_getOriginInput(), @model.getOriginLocked()

        _getDestinationInputText: =>
            @_getInputText @model.getDestination(), @_getDestinationInput(), @model.getDestinationLocked()

        swapEndpoints: (event) ->
            event.stopPropagation()
            @model.swapEndpoints
                silent: true
            if @model.isComplete()
                @applyChanges()

        _setInputValue: (input, value) ->
            input.focus().val value
            # This is for IE 10+
            if input[0].setSelectionRange
                input[0].setSelectionRange(value.length, value.length);

        editInput: (event) ->
            event.stopPropagation()
            if !@editing
                @editing = true
                # This is to make users life easier by focusing cursor
                # to the end of the line and also making sure that user
                # has the right input to edit
                switch $(event.currentTarget).attr 'data-endpoint'
                    when 'origin'
                        @_setInputValue @_getOriginInput(), @_getOriginInputText()
                    when 'destination'
                        @_setInputValue @_getDestinationInput(), @_getDestinationInputText()

        serializeData: ->
            origin_name: @_getOriginInputText()
            destination_name: @_getDestinationInputText()

        _processLocationDetection: (position) ->
            p13n.requestLocation position
            ,() =>
                position.setDetected(true)
                @applyChanges()
            ,() =>
                position.setFailed(true)
                @applyChanges()

        detectCurrentLocation: (event) ->
            event.preventDefault()
            event.stopPropagation()
            if not @model.hasDetectedLocation()
                if @model.getOriginLocked()
                    @model.setDestination new models.CoordinatePosition
                    @_processLocationDetection @model.getDestination()
                else
                    @model.setOrigin new models.CoordinatePosition
                    @_processLocationDetection @model.getOrigin()

    class RouteSettingsHeaderView extends base.SMItemView
        template: 'route-settings-header'
        events:
            'click .ok-button': 'toggleSettingsVisibility'
        toggleSettingsVisibility: (event) ->
            event.preventDefault()
            $('#route-details').toggleClass('settings-open')
            $('.bootstrap-datetimepicker-widget').hide()

    class TransportModeControlsView extends base.SMItemView
        template: 'transport-mode-controls'
        events:
            'click .transport-modes a': 'switchTransportMode'

        onDomRefresh: =>
            _(['public', 'bicycle']).each (group) =>
                @$el.find(".#{group}-details a").click (event) =>
                    event.preventDefault()
                    @switchTransportDetails event, group

        serializeData: ->
            transportModes = p13n.get('transport')
            bicycleDetailsClasses = ''
            if transportModes.public_transport
                bicycleDetailsClasses += 'no-arrow '
            unless transportModes.bicycle
                bicycleDetailsClasses += 'hidden'
            selectedValues = (modes) =>
                _(modes)
                    .chain()
                    .pairs()
                    .filter (v) => v[1] == true
                    .map (v) => v[0]
                    .value()
            transportModes = selectedValues transportModes
            publicModes = selectedValues p13n.get('transport_detailed_choices').public

            transport_modes: transportModes
            public_modes: publicModes
            transport_detailed_choices: p13n.get('transport_detailed_choices')
            bicycle_details_classes: bicycleDetailsClasses

        switchTransportMode: (event) ->
            event.preventDefault()
            type = $(event.target).closest('li').data 'type'
            p13n.toggleTransport type
            @render()

        switchTransportDetails: (event, group) ->
            event.preventDefault()
            type = $(event.target).closest('li').data 'type'
            p13n.toggleTransportDetails group, type
            @render()

    class RouteControllersView extends base.SMItemView
        template: 'route-controllers'
        events:
            'click .preset-current-time': 'switchToTimeInput'
            'click .preset-current-date': 'switchToDateInput'
            'click .time-mode': 'setTimeMode'
            'click': 'undoChanges'
            # Important: the above click handler requires the following
            # to not disable the time picker widget.
            'click .time': (event) -> event.stopPropagation()
            'click .date': (event) -> event.stopPropagation()

        initialize: (attrs) ->
            window.debugRoutingControls = @
            @permanentModel = @model
            @currentUnit = attrs.unit
            @_reset()

        _reset: ->
            @stopListening @model
            @model = @permanentModel.clone()
            @listenTo @model, 'change', (model, options) =>
                # If the change was an interaction with the datetimepicker
                # widget, we shouldn't re-render.
                unless options?.alreadyVisible
                    @$el.find('input.time').data("DateTimePicker")?.hide()
                    @$el.find('input.time').data("DateTimePicker")?.destroy()
                    @$el.find('input.date').data("DateTimePicker")?.hide()
                    @$el.find('input.date').data("DateTimePicker")?.destroy()
                    @render()

        onDomRefresh: ->
            @enableDatetimePicker()

        enableDatetimePicker: ->
            keys = ['time', 'date']
            other = (key) =>
                keys[keys.indexOf(key) + 1 % keys.length]
            inputElement = (key) =>
                @$el.find "input.#{key}"
            otherHider = (key) => =>
                inputElement(other(key)).data("DateTimePicker")?.hide()
            valueSetter = (key) => (event) =>
                keyUpper = key.charAt(0).toUpperCase() + key.slice 1
                @model["set#{keyUpper}"].call @model, event.date.toDate(),
                    alreadyVisible: true
                @applyChanges()

            closePicker = true
            _.each keys, (key) =>
                $input = inputElement key
                if $input.length > 0
                    options = {}
                    disablePick = (
                        time: 'pickDate'
                        date: 'pickTime'
                    )[key]
                    options[disablePick] = false

                    $input.datetimepicker options
                    $input.on 'dp.show', =>
                        # If a different picker is shown, don't close
                        # it immediately.
                        # TODO: get rid of unnecessarily complex open/close logic
                        if @activateOnRender != 'date' and @shown? and @shown != key then closePicker = false
                        otherHider(key)()
                        @shown = key
                    $input.on 'dp.change', valueSetter(key)
                    dateTimePicker = $input.data("DateTimePicker")
                    $input.on 'click', =>
                        if closePicker then @_closeDatetimePicker $input
                        closePicker = !closePicker
                    if @activateOnRender == key
                        dateTimePicker.show()
                        $input.attr 'readonly', @_isScreenHeightLow()
            @activateOnRender = null

        applyChanges: ->
            @permanentModel.set @model.attributes
            @permanentModel.triggerComplete()
        undoChanges: ->
            @_reset()
            @model.trigger 'change'

        _isScreenHeightLow: ->
            $(window).innerHeight() < 700

        serializeData: ->
            datetime = moment @model.getDatetime()
            today = new Date()
            tomorrow = moment(today).add 1, 'days'
            # try to avoid opening the mobile virtual keyboard
            disable_keyboard: @_isScreenHeightLow()
            is_today: not @forceDateInput and datetime.isSame(today, 'day')
            is_tomorrow: datetime.isSame tomorrow, 'day'
            params: @model
            time: datetime.format 'LT'
            date: datetime.format 'L'
            time_mode: @model.get 'time_mode'

        setTimeMode: (event) ->
            event.stopPropagation()
            timeMode = $(event.target).data('value')
            if timeMode != @model.get 'time_mode'
                @model.setTimeMode(timeMode)
                @applyChanges()

        _closeDatetimePicker: ($input) ->
            $input.data("DateTimePicker").hide()
        switchToTimeInput: (event) ->
            event.stopPropagation()
            @activateOnRender = 'time'
            @model.setDefaultDatetime()
        switchToDateInput: (event) ->
            event.stopPropagation()
            @activateOnRender = 'date'
            @forceDateInput = true
            @model.trigger 'change'

    RouteSettingsView
