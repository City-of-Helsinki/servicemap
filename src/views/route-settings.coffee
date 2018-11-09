define (require) ->
    _                  = require 'underscore'
    moment             = require 'moment'
    datetimepicker     = require 'bootstrap-datetimepicker'

    p13n               = require 'cs!app/p13n'
    models             = require 'cs!app/models'
    search             = require 'cs!app/search'
    base               = require 'cs!app/views/base'
    accessibilityViews = require 'cs!app/views/accessibility'
    geocoding          = require 'cs!app/geocoding'
    jade               = require 'cs!app/jade'

    class RouteSettingsView extends base.SMLayout
        template: 'route-settings'
        regions:
            'headerRegion': '.route-settings-header'
            'routeControllersRegion': '.route-controllers'
            'accessibilitySummaryRegion': '.accessibility-viewpoint-part'
            'transportModeControlsRegion': '.transport_mode_controls'

        initialize: (attrs) ->
            @unit = attrs.unit
            @listenTo @model, 'change', @updateRegions

        onShow: ->
            @headerRegion.show new RouteSettingsHeaderView
                model: @model
            @routeControllersRegion.show new RouteControllersView
                model: @model
                unit: @unit
            @accessibilitySummaryRegion.show new accessibilityViews.AccessibilityViewpointView
                filterTransit: true
                template: 'accessibility-viewpoint-oneline'
            @transportModeControlsRegion.show new TransportModeControlsView

        updateRegions: ->
            @headerRegion.currentView.render()
            @accessibilitySummaryRegion.currentView.render()
            @transportModeControlsRegion.currentView.render()
            @routeControllersRegion.currentView.render()


    class RouteSettingsHeaderView extends base.SMItemView
        template: 'route-settings-header'
        events:
            'click .settings-summary': 'toggleSettingsVisibility'
            'click .ok-button': 'toggleSettingsVisibility'

        serializeData: ->
            profiles = p13n.getAccessibilityProfileIds true

            origin = @model.getOrigin()
            originName = @model.getEndpointName origin
            if (
                (origin?.isDetectedLocation() and not origin?.isPending()) or
                (origin? and origin instanceof models.CoordinatePosition)
            )
                originName = originName.toLowerCase()

            transportIcons = []
            for mode, value of p13n.get('transport')
                if value
                    transportIcons.push "icon-icon-#{mode.replace('_', '-')}"

            profile_set: _.keys(profiles).length
            profiles: p13n.getProfileElements profiles
            origin_name: originName
            origin_is_pending: @model.getOrigin().isPending()
            transport_icons: transportIcons

        toggleSettingsVisibility: (event) ->
            event.preventDefault()
            $('#route-details').toggleClass('settings-open')
            $('.bootstrap-datetimepicker-widget').hide()
            $originEndpointEl = $('#route-details').find('.transit-start .endpoint')
            if $originEndpointEl.is(':visible')
                $originEndpointEl.focus()

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

        switchTransportDetails: (event, group) ->
            event.preventDefault()
            type = $(event.target).closest('li').data 'type'
            p13n.toggleTransportDetails group, type

    class RouteControllersView extends base.SMItemView
        template: 'route-controllers'
        events:
            'click .detect-current-location': 'detectCurrentLocation'
            'click input': 'editInput'

            'click .preset-current-time': 'switchToTimeInput'
            'click .preset-current-date': 'switchToDateInput'
            'click .time-mode': 'setTimeMode'
            'click .swap-endpoints': 'swapEndpoints'
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click': 'undoChanges'
            # Important: the above click handler requires the following
            # to not disable the time picker widget.
            'click .time': (event) -> event.stopPropagation()
            'click .date': (event) -> event.stopPropagation()

        initialize: (attrs) ->
            window.debugRoutingControls = @
            @permanentModel = @model
            @pendingPosition = @permanentModel.pendingPosition
            @currentUnit = attrs.unit
            @editing = false
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
            @listenTo @model.getOrigin(), 'change', @render
            @listenTo @model.getDestination(), 'change', @render

        _getOriginInput: ->
            @$el.find '.transit-start input.tt-input'
        _getDestinationInput: ->
            @$el.find '.transit-end input.tt-input'

        onDomRefresh: ->
            @enableTypeahead '.transit-start input'
            @enableTypeahead '.transit-end input'
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
            @editing = false
            @permanentModel.set @model.attributes
            @permanentModel.triggerComplete()
        undoChanges: ->
            @_reset()
            @model.trigger 'change'

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
                @render()

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

        _isScreenHeightLow: ->
            $(window).innerHeight() < 700

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

        _getOriginInputText: =>
            @_getInputText @model.getOrigin(), @_getOriginInput(), @model.getOriginLocked()

        _getDestinationInputText: =>
            @_getInputText @model.getDestination(), @_getDestinationInput(), @model.getDestinationLocked()

        serializeData: ->
            datetime = moment @model.getDatetime()
            today = new Date()
            tomorrow = moment(today).add 1, 'days'
            # try to avoid opening the mobile virtual keyboard
            disable_keyboard: @_isScreenHeightLow()
            is_today: not @forceDateInput and datetime.isSame(today, 'day')
            is_tomorrow: datetime.isSame tomorrow, 'day'
            params: @model
            origin:
                name: @_getOriginInputText()
                lock: @model.getOriginLocked()
            destination:
                name: @_getDestinationInputText()
                lock: @model.getDestinationLocked()
            time: datetime.format 'LT'
            date: datetime.format 'L'
            time_mode: @model.get 'time_mode'

        swapEndpoints: (event) ->
            event.stopPropagation()
            @permanentModel.swapEndpoints
                silent: true
            @model.swapEndpoints()
            if @model.isComplete()
                @applyChanges()
                @render()

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

        _processLocationDetection: (position) ->
            p13n.requestLocation position
            ,() =>
                position.setDetected(true)
                @applyChanges()
                @render()
            ,() =>
                position.setPending(false)
                @render()

        detectCurrentLocation: (event) ->
            event.preventDefault()
            event.stopPropagation()
            if @model.getOriginLocked()
                @model.setDestination new models.CoordinatePosition
                @_processLocationDetection @model.getDestination()
            else
                @model.setOrigin new models.CoordinatePosition
                @_processLocationDetection @model.getOrigin()

    RouteSettingsView
