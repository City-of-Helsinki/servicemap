define [
    'underscore',
    'moment',
    'bootstrap-datetimepicker',
    'cs!app/p13n',
    'cs!app/models',
    'cs!app/search',
    'cs!app/views/base',
    'cs!app/views/accessibility',
    'cs!app/geocoding',
    'cs!app/jade'
], (
    _,
    moment,
    datetimepicker,
    p13n,
    models,
    search,
    base,
    accessibilityViews,
    geocoding,
    jade
) ->

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

        onRender: ->
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
            $('#route-details').trigger "shown"

    class TransportModeControlsView extends base.SMItemView
        template: 'transport-mode-controls'
        events:
            'click .transport-modes a': 'switchTransportMode'

        onRender: =>
            _(['public', 'bicycle']).each (group) =>
                @$el.find(".#{group}-details a").click (ev) =>
                    ev.preventDefault()
                    @switchTransportDetails ev, group

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

        switchTransportMode: (ev) ->
            ev.preventDefault()
            type = $(ev.target).closest('li').data 'type'
            p13n.toggleTransport type

        switchTransportDetails: (ev, group) ->
            ev.preventDefault()
            type = $(ev.target).closest('li').data 'type'
            p13n.toggleTransportDetails group, type

    class RouteControllersView extends base.SMItemView
        template: 'route-controllers'
        events:
            'click .preset.unlocked': 'switchToLocationInput'
            'click .preset-current-time': 'switchToTimeInput'
            'click .preset-current-date': 'switchToDateInput'
            'click .time-mode': 'setTimeMode'
            'click .swap-endpoints': 'swapEndpoints'
            'click .tt-suggestion': (e) ->
                e.stopPropagation()
            'click': 'undoChanges'
            # Important: the above click handler requires the following
            # to not disable the time picker widget.
            'click .time': (ev) -> ev.stopPropagation()
            'click .date': (ev) -> ev.stopPropagation()

        initialize: (attrs) ->
            window.debugRoutingControls = @
            @permanentModel = @model
            @pendingPosition = @permanentModel.pendingPosition
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
            @listenTo @model.getOrigin(), 'change', @render
            @listenTo @model.getDestination(), 'change', @render

        onRender: ->
            @enableTypeahead '.transit-end input'
            @enableTypeahead '.transit-start input'
            @enableDatetimePicker()

        enableDatetimePicker: ->
            keys = ['time', 'date']
            other = (key) =>
                keys[keys.indexOf(key) + 1 % keys.length]
            inputElement = (key) =>
                @$el.find "input.#{key}"
            otherHider = (key) => =>
                inputElement(other(key)).data("DateTimePicker")?.hide()
            valueSetter = (key) => (ev) =>
                keyUpper = key.charAt(0).toUpperCase() + key.slice 1
                @model["set#{keyUpper}"].call @model, ev.date.toDate(),
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
            origin = @model.getOrigin()
            destination = @model.getDestination()
            @model.trigger 'change'

        enableTypeahead: (selector) ->
            @$searchEl = @$el.find selector
            unless @$searchEl.length
                return

            geocoderBackend = new geocoding.GeocoderSourceBackend()
            options = geocoderBackend.getDatasetOptions()
            options.templates.empty = (ctx) -> jade.template 'typeahead-no-results', ctx
            @$searchEl.typeahead null, [options]

            @$searchEl.on 'keyup', (e) =>
                $('.tt-suggestion:first-child').trigger('click') if e.keyCode is 13

            selectAddress = (event, match) =>
                @commit = true
                switch $(event.currentTarget).attr 'data-endpoint'
                    when 'origin'
                        @model.setOrigin match
                    when 'destination'
                        @model.setDestination match

                @applyChanges()

            geocoderBackend.setOptions
                $inputEl: @$searchEl
                selectionCallback: selectAddress

            # Focus on search-elem when #route-details has been opened
            $('#route-details').on "shown", =>
                @$searchEl.attr('tabindex', -1).focus()

        _locationNameAndLocking: (object) ->
            name: @model.getEndpointName object
            lock: @model.getEndpointLocking object

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
            origin: @_locationNameAndLocking @model.getOrigin()
            destination: @_locationNameAndLocking @model.getDestination()
            time: datetime.format 'LT'
            date: datetime.format 'L'
            time_mode: @model.get 'time_mode'

        swapEndpoints: (ev) ->
            ev.stopPropagation()
            @permanentModel.swapEndpoints
                silent: true
            @model.swapEndpoints()
            if @model.isComplete()
                @applyChanges()

        switchToLocationInput: (ev) ->
            ev.stopPropagation()
            @_reset()
            position = @pendingPosition
            position.clear()
            switch $(ev.currentTarget).attr 'data-route-node'
                when 'start' then @model.setOrigin position
                when 'end' then @model.setDestination position
            @listenToOnce position, 'change', =>
                @applyChanges()
                @render()
            position.trigger 'request'

        setTimeMode: (ev) ->
            ev.stopPropagation()
            timeMode = $(ev.target).data('value')
            if timeMode != @model.get 'time_mode'
                @model.setTimeMode(timeMode)
                @applyChanges()

        _closeDatetimePicker: ($input) ->
            $input.data("DateTimePicker").hide()
        switchToTimeInput: (ev) ->
            ev.stopPropagation()
            @activateOnRender = 'time'
            @model.setDefaultDatetime()
        switchToDateInput: (ev) ->
            ev.stopPropagation()
            @activateOnRender = 'date'
            @forceDateInput = true
            @model.trigger 'change'

    RouteSettingsView
