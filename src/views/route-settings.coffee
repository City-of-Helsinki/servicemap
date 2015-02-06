define [
    'underscore',
    'moment',
    'bootstrap-datetimepicker',
    'app/p13n',
    'app/models',
    'app/search',
    'app/views/base',
    'app/views/accessibility'
], (
    _,
    moment,
    datetimepicker,
    p13n,
    models,
    search,
    base,
    accessibilityViews,
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
            @userClickCoordinatePosition = attrs.userClickCoordinatePosition
            @listenTo @model, 'change', @updateRegions

        onRender: ->
            @headerRegion.show new RouteSettingsHeaderView
                model: @model
            @routeControllersRegion.show new RouteControllersView
                model: @model
                unit: @unit
                userClickCoordinatePosition: @userClickCoordinatePosition
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

            transport_modes: transportModes
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
            'click': 'undoChanges'
            # Important: the above click handler requires the following
            # to not disable the time picker widget.
            'click .time': (ev) -> ev.stopPropagation()
            'click .date': (ev) -> ev.stopPropagation()

        initialize: (attrs) ->
            window.debugRoutingControls = @
            @permanentModel = @model
            @currentUnit = attrs.unit
            @userClickCoordinatePosition = attrs.userClickCoordinatePosition
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
                keys[keys.indexOf(key) % keys.length]
            inputElement = (key) =>
                @$el.find "input.#{key}"
            otherHider = (key) => =>
                inputElement(other(key)).data("DateTimePicker")?.hide()
            valueSetter = (key) => (ev) =>
                @model["set#{key.charAt(0).toUpperCase() + key.slice 1}"].call @model, ev.date.toDate(),
                    alreadyVisible: true
                @applyChanges()

            for key in keys
                $input = inputElement key
                if $input.length > 0
                    options = {}
                    disablePick = switch key
                        when 'time' then 'pickDate'
                        when 'date' then 'pickTime'
                    options[disablePick] = false
                    $input.datetimepicker options
                    $input.on 'dp.show', otherHider()
                    $input.on 'dp.change', valueSetter(key)
                    if @activateOnRender == "#{key}_input"
                        $input.data("DateTimePicker").show()
            @activateOnRender = null

        applyChanges: ->
            @permanentModel.set @model.attributes
            @permanentModel.triggerComplete()
        undoChanges: ->
            @_reset()
            origin = @model.getOrigin()
            destination = @model.getDestination()
            if origin instanceof models.CoordinatePosition
                @userClickCoordinatePosition.wrap origin
            else if destination instanceof models.CoordinatePosition
                @userClickCoordinatePosition.wrap destination
            @model.trigger 'change'

        enableTypeahead: (selector) ->
            @$searchEl = @$el.find selector
            unless @$searchEl.length
                return
            addressDataset =
                source: search.geocoderEngine.ttAdapter(),
                displayKey: (c) -> c.name
                templates:
                    empty: (ctx) -> jade.template 'typeahead-no-results', ctx
                    suggestion: (ctx) -> ctx.name

            @$searchEl.typeahead null, [addressDataset]

            selectAddress = (event, match) =>
                @commit = true
                addressPosition = new models.AddressPosition match

                switch $(event.currentTarget).attr 'data-endpoint'
                    when 'origin'
                        @model.setOrigin addressPosition
                    when 'destination'
                        @model.setDestination addressPosition

                @applyChanges()

            @$searchEl.on 'typeahead:selected', (event, match) =>
                selectAddress event, match
            @$searchEl.on 'typeahead:autocompleted', (event, match) =>
                selectAddress event, match
            @$searchEl.keydown (ev) =>
                if ev.keyCode == 9 # tabulator
                    @undoChanges()
            # TODO figure out why focus doesn't work
            @$searchEl.focus()

        _locationNameAndLocking: (object) ->
            name: @model.getEndpointName object
            lock: @model.getEndpointLocking object

        serializeData: ->
            datetime = moment @model.getDatetime()
            today = new Date()
            tomorrow = moment(today).add 1, 'days'
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
            position = new models.CoordinatePosition
                isDetected: false
            @userClickCoordinatePosition.wrap position
            switch $(ev.currentTarget).attr 'data-route-node'
                when 'start' then @model.setOrigin position
                when 'end' then @model.setDestination position
            @listenTo position, 'change', =>
                @applyChanges()
                @render()
            position.trigger 'request'

        setTimeMode: (ev) ->
            ev.stopPropagation()
            timeMode = $(ev.target).data('value')
            if timeMode != @model.get 'time_mode'
                @model.setTimeMode(timeMode)
                @applyChanges()

        switchToTimeInput: (ev) ->
            ev.stopPropagation()
            @activateOnRender = 'time_input'
            @model.setDefaultDatetime()
        switchToDateInput: (ev) ->
            ev.stopPropagation()
            @activateOnRender = 'date_input'
            @forceDateInput = true
            @model.trigger 'change'

    RouteSettingsView
