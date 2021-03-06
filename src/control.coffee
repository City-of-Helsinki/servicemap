define (require) ->
    $          = require 'jquery'
    Marionette = require 'backbone.marionette'
    URI        = require 'URI'
    Raven      = require 'raven'

    sm         = require 'cs!app/base'
    Models     = require 'cs!app/models'
    Analytics  = require 'cs!app/analytics'

    renderUnitsByOldServiceId = require 'cs!app/redirect'

    GeocodeCleanup = require 'cs!app/geocode-cleanup'
    { SUBWAY_STATION_SERVICE_ID } = require 'cs!app/transit'

    PAGE_SIZE = appSettings.page_size

    _unit_minimal_only_fields = [
        'root_service_nodes',
        'services',
        'location',
        'name',
        'street_address',
        'contract_type',
    ]

    UNIT_MINIMAL_ONLY_FIELDS = _unit_minimal_only_fields.join(',')
    UNIT_SEARCH_MINIMAL_ONLY_FIELDS = (_(_unit_minimal_only_fields).map (f) -> "unit.#{f}").join(',')

    class BaseControl extends Marionette.Controller
        initialize: (appModels) ->
            @models = appModels
            # Units currently on the map
            @units = appModels.units
            @stopUnits = appModels.stopUnits
            # Services and ServiceNodes in the cart
            @selectedServices = appModels.selectedServices
            @serviceNodes = appModels.selectedServiceNodes
            # Selected units (always of length zero or one)
            @selectedUnits = appModels.selectedUnits
            @selectedPosition = appModels.selectedPosition
            @searchResults = appModels.searchResults
            @divisions = appModels.divisions
            @statistics = appModels.statistics
            @selectedDivision = appModels.selectedDivision
            @selectedDataLayers = appModels.selectedDataLayers
            @level = appModels.level
            @dataLayers = appModels.dataLayers
            @informationalMessage = appModels.informationalMessage
            @notificationMessage = appModels.notificationMessage
            @transitStops = appModels.transitStops

        setMapProxy: (@mapProxy) ->

        setUnits: (units, filter) ->
            @serviceNodes.set []
            @selectedServices.set []
            @_setSelectedUnits()
            @units.reset units.toArray()
            if filter?
                @units.setFilter filter, true
            else
                @units.clearFilters()
            # Current cluster based map logic
            # requires batch reset signal.

        setUnit: (unit) ->
            @serviceNodes.set []
            @selectedServices.set []
            @units.reset [unit]

        getUnit: (id) ->
            return @units.get id

        _setSelectedUnits: (units, options) ->
            @selectedUnits.each (u) -> u.set 'selected', false
            if units?
                _(units).each (u) -> u.set 'selected', true
                @selectedUnits.reset units, options
            else
                if @selectedUnits.length
                    @selectedUnits.reset [], options

        _unselectPosition: ->
            # unselected position is left on the map for user reference
            # but marked as unselected to help with event resolution
            # precedence
            @selectedPosition.value()?.set? 'selected', false

        selectUnit: (unit, opts) ->
            addUnit = (unit) =>
                if opts?.replace
                    @units.reset [unit]
                    @units.clearFilters()
                else if opts?.overwrite or not @units.contains unit
                    @units.add unit
                    @units.trigger 'reset', @units
            hasObject = (unit, key) ->
                o = unit.get(key)
                o? and typeof o == 'object'
            @selectedDivision.clear()
            @_setSelectedUnits? [unit], silent: true
            requiredObjects = ['department', 'municipality', 'services', 'geometry', 'service_nodes']
            unless _(requiredObjects).find((x)->!hasObject(unit, x))
                addUnit unit
                @selectedUnits.trigger 'reset', @selectedUnits
                sm.resolveImmediately()
            else
                unit.fetch
                    data:
                        include: 'department,municipality,service_nodes,services'
                        geometry: true
                    success: =>
                        addUnit unit
                        @selectedUnits.trigger 'reset', @selectedUnits

        addUnitsWithinBoundingBoxes: (bboxStrings, level) ->
            if level == 'none'
                return
            unless level?
                level = 'customer_service'
            bboxCount = bboxStrings.length
            if bboxCount > 4
                null
                # TODO: handle case.
            if @selectedPosition.value()?.get('radiusFilter')?
                return

            @units.clearFilters()

            getBbox = (bboxStrings) =>
                # Fetch bboxes sequentially
                if bboxStrings.length == 0
                    @units.setFilter 'bbox', true
                    @units.trigger 'finished',
                        keepViewport: true
                    return
                bboxString = _.first bboxStrings
                unitList = new models.UnitList null, forcedPriority: false
                opts =
                    data:
                        only: UNIT_MINIMAL_ONLY_FIELDS
                        geometry: 'true'
                    success: (coll, resp, options) =>
                        if unitList.length
                            @units.add unitList.toArray()
                        unless unitList.fetchNext(opts)
                            unitList.trigger 'finished',
                            keepViewport: true
                unitList.pageSize = PAGE_SIZE
                unitList.setFilter 'bbox', bboxString
                layer = p13n.get 'map_background_layer'
                unitList.setFilter 'bbox_srid', if layer in ['servicemap', 'accessible_map'] then 3067 else 3879
                if level?
                    unitList.setFilter 'level', level

                @listenTo unitList, 'finished', =>
                    getBbox _.rest(bboxStrings)
                unitList.fetch(opts)

            getBbox(bboxStrings)

        addStopUnitsWithinBoundingBoxes: (bboxStrings, level) ->
            if level == 'none'
                return
            unless level?
                level = 'customer_service'

            bboxCount = bboxStrings.length
            if bboxCount > 4
                null
                # TODO: handle case.

            @stopUnits.clearFilters()

            getBbox = (bboxStrings) =>
                # Fetch bboxes sequentially
                if bboxStrings.length == 0
                    @stopUnits.setFilter 'bbox', true
                    @stopUnits.trigger 'finished',
                        keepViewport: true
                    return
                bboxString = _.first bboxStrings
                unitList = new models.UnitList null, forcedPriority: false
                opts =
                    data:
                        only: UNIT_MINIMAL_ONLY_FIELDS
                        geometry: 'true'
                        service: SUBWAY_STATION_SERVICE_ID
                    success: (coll, resp, options) =>
                        if unitList.length
                            @stopUnits.add unitList.toArray()
                        unless unitList.fetchNext(opts)
                            unitList.trigger 'finished',
                            keepViewport: true
                unitList.pageSize = PAGE_SIZE
                unitList.setFilter 'bbox', bboxString
                layer = p13n.get 'map_background_layer'
                unitList.setFilter 'bbox_srid', if layer in ['servicemap', 'accessible_map'] then 3067 else 3879
                if level?
                    unitList.setFilter 'level', level

                @listenTo unitList, 'finished', =>
                    getBbox _.rest(bboxStrings)
                unitList.fetch(opts)

            getBbox(bboxStrings)

        _clearRadius: ->
        clearSearchResults: ->
        clearUnits: ->
        reset: ->

        toggleDivision: (division) =>
            @_clearRadius()
            old = @selectedDivision.value()
            if old? then old.set 'selected', false
            if division == old
                @selectedDivision.clear()
            else
                @selectedDivision.wrap division
                id = @selectedDivision.attributes.value.attributes.unit?.id or null
                # clear @units so the previous one doesn't persist if there is no new unit to draw
                if id? then @renderUnitById(id, false) else @units.set []
                division.set 'selected', true

        renderUnitById: (id, unitSelect=true) ->
            deferred = $.Deferred()
            unit = new Models.Unit id: id
            unit.fetch
                data:
                    include: 'department,municipality,service_nodes,services'
                    geometry: 'true'
                success: =>
                    @setUnit unit
                    if unitSelect then @selectUnit unit
                    deferred.resolve unit
            deferred.promise()

        selectPosition: (position) ->
            position.set 'selected', true
            @clearSearchResults?()
            @_setSelectedUnits?()
            previous = @selectedPosition.value()
            if previous?.get('radiusFilter')?
                @units.reset []
                @units.clearFilters()
            if position == previous
                @selectedPosition.trigger 'change:value', @selectedPosition, @selectedPosition.value()
            else
                @selectedPosition.wrap position
            sm.resolveImmediately()

        requestStopsByBbox: ({ minLat, maxLat, minLon, maxLon }) ->
            # Pad coordinates by about 250 metres in both directions
            # to fetch information about closest stops for subway stations
            PADDING_LATITUDE = 0.00225
            PADDING_LONGITUDE = 0.00452

            @transitStops.fetch
                minLat: minLat - PADDING_LATITUDE
                maxLat: maxLat + PADDING_LATITUDE
                minLon: minLon - PADDING_LONGITUDE
                maxLon: maxLon + PADDING_LONGITUDE

        setRadiusFilter: (radius, cancelToken) ->
            @selectedServices.reset [], skip_navigate: true
            @serviceNodes.reset [], skip_navigate: true
            @units.reset []
            @units.clearFilters()
            keys = ['distance_precalculated', 'alphabetic', 'alphabetic_reverse']
            @units.setOverrideComparatorKeys keys, 'distance_precalculated'
            if @selectedPosition.isEmpty()
                return

            pos = @selectedPosition.value()
            unitList = new models.UnitList [], pageSize: PAGE_SIZE
                .setFilter 'lat', pos.get('location').coordinates[1]
                .setFilter 'lon', pos.get('location').coordinates[0]
                .setFilter 'distance', radius
            opts =
                data:
                    only: UNIT_MINIMAL_ONLY_FIELDS
                    include: 'service_nodes,services,accessibility_properties'
                onPageComplete: =>
                    @units.add unitList.toArray(), merge: true
                    @units.setFilters unitList
                cancelToken: cancelToken
            cancelToken.activate()
            unitList.fetchPaginated(opts).done =>
                pos.set 'radiusFilter', radius, {cancelToken}
                @units.trigger 'finished', refit: true

        clearRadiusFilter: ->
            @_clearRadius()
            @selectPosition @selectedPosition.value() unless @selectedPosition.isEmpty()

        ###
        (itemType: 'service' | 'serviceNode'
        serviceItem: models.Service | models.ServiceNode
        collection: models.ServiceList | models.ServiceNodeList
        filters: Object
        cancelToken: CancelToken) => Promise<void>
        ###
        _addServiceItem: (itemType, serviceItem, collection, filters, cancelToken) ->
            cancelToken.activate()
            @_clearRadius()
            @_setSelectedUnits()

            if collection.has serviceItem
                cancelToken.complete()
                collection.trigger 'has-service-item', serviceItem
                return sm.resolveImmediately()

            collection.add serviceItem

            if itemType == 'serviceNode' and serviceItem.has 'ancestors'
                ancestor = collection.find (s) ->
                    s.id in serviceItem.get 'ancestors'
                if ancestor?
                    @removeServiceNode ancestor

            @_fetchServiceItemUnits itemType, serviceItem, filters, cancelToken

        _fetchServiceItemUnits: (itemType, serviceItem, filters, cancelToken) ->
            setComparator = appSettings.is_embedded != true
            unitList = new models.UnitList [], pageSize: PAGE_SIZE, setComparator: setComparator
            if filters? then unitList.filters = filters

            typeFilterFields =
                serviceNode: 'service_node'
                service: 'service'

            if itemType of typeFilterFields
                unitList.setFilter typeFilterFields[itemType], serviceItem.id
            else
                console.warn 'Unknown object type', { itemType, serviceItem }

            # MunicipalityIds come from explicit query parameters
            # and they always override the user p13n city setting.
            # If no explicit parameters received, use p13n profile
            municipalityIds = filters?.municipality or p13n.getCities()

            if municipalityIds.length > 0
                unitList.setFilter 'municipality', municipalityIds.join(',')

            opts =
                # todo: re-enable
                #spinnerTarget: spinnerTarget
                data:
                    only: UNIT_MINIMAL_ONLY_FIELDS
                    include: 'service_nodes,services,accessibility_properties'
                    geometry: 'true'
                onPageComplete: ->
                cancelToken: cancelToken

            maybe = (op) =>
                op() unless cancelToken.canceled()
            unitList.fetchPaginated(opts).done (collection) =>
                if @serviceNodes.length + @selectedServices.length == 1
                    # Remove possible units that had been added through
                    # other means than serviceNode selection.
                    maybe => @units.reset []
                    @units.clearFilters()
                    @clearSearchResults navigate: false
                @units.add unitList.toArray(), merge: true
                maybe => serviceItem.get('units').add unitList.toArray()
                cancelToken.set 'cancelable', false
                cancelToken.set 'status', 'rendering'
                cancelToken.set 'progress', null
                @units.setOverrideComparatorKeys ([
                    'alphabetic', 'alphabetic_reverse', 'distance'])
                _.defer =>
                    # Defer needed to make sure loading indicator gets a chance
                    # to re-render before drawing.
                    @_unselectPosition()
                    maybe => @units.trigger 'finished', refit: true, cancelToken: cancelToken
                    maybe => serviceItem.get('units').trigger 'finished'

        addServiceNode: (serviceNode, filters, cancelToken) ->
            console.assert(cancelToken?.constructor?.name == 'CancelToken', 'wrong canceltoken parameter')
            if serviceNode.has('ancestors')
                @_addServiceItem 'serviceNode', serviceNode, @serviceNodes, filters, cancelToken
            else
                serviceNode.fetch(data: include: 'ancestors').then =>
                    @_addServiceItem 'serviceNode', serviceNode, @serviceNodes, filters, cancelToken

        addServiceNodes: (serviceNodes) ->
            sm.resolveImmediately()

        removeServiceNode: (serviceNodeId) ->
            @_removeServiceItem serviceNodeId, @serviceNodes

        removeServiceNodes: () ->
            @serviceNodes.reset()

        addService: (service, filters, cancelToken) ->
            @_addServiceItem 'service', service, @selectedServices, filters, cancelToken

        setService: (service, cancelToken) ->
            @_setServiceItem service, @addService, cancelToken

        removeService: (serviceId) ->
            @_removeServiceItem serviceId, @selectedServices

        _setServiceItem: (serviceItem, addMethod, cancelToken) ->
            @selectedServices.set []
            @serviceNodes.set []
            addMethod.call @, serviceItem, {}, cancelToken

        _removeServiceItem: (id, collection) ->
            serviceItem = collection.get id
            collection.remove serviceItem
            unitsForItem = serviceItem.get 'units'

            if unitsForItem.length == 0
                return sm.resolveImmediately()

            otherServiceItems = collection.filter (item) -> item != serviceItem
            unitsToRemove = unitsForItem.reject (unit) =>
                @selectedUnits.get(unit)? or
                _(otherServiceItems).find (item) -> item.get('units').get(unit)?

            @removeUnits unitsToRemove

            if @serviceNodes.length == 0 and @selectedServices.length == 0 and @selectedPosition.isSet()
                @selectPosition @selectedPosition.value()
                @selectedPosition.trigger 'change:value', @selectedPosition, @selectedPosition.value()

            sm.resolveImmediately()

        _search: (query, filters, cancelToken) ->
            sm.withDeferred (deferred) =>
                if @searchResults.query == query
                    @searchResults.trigger 'ready'
                    deferred.resolve()
                    return

                cancelToken.activate()
                @_clearRadius()
                @selectedPosition.clear()
                @clearUnits all: true
                canceled = false
                @listenToOnce cancelToken, 'canceled', -> canceled = true

                if 'search' in _(@units.filters).keys()
                    @units.reset []
                unless @searchResults.isEmpty()
                    @searchResults.reset []

                @searchResults.pageSize = 1000
                opts =
                    onPageComplete: =>
                        if _paq?
                            _paq.push ['trackSiteSearch', query, false, @searchResults.models.length]
                        @units.add @searchResults.filter (r) ->
                            r.get('object_type') == 'unit'
                        @units.setFilter 'search', true
                    cancelToken: cancelToken
                    data: {}

                if filters? and _.size(filters) > 0
                    opts.data = filters
                opts.data.only = UNIT_SEARCH_MINIMAL_ONLY_FIELDS

                opts = @searchResults.search(query, opts).done =>
                    return if canceled
                    @_unselectPosition()
                    return if canceled
                    @searchResults.trigger 'ready'
                    return if canceled
                    @units.trigger 'finished'
                    @serviceNodes.set []
                    @selectedServices.set []
                    deferred.resolve()

        search: (query, filters, cancelToken) ->
            console.assert(cancelToken.constructor.name == 'CancelToken', 'wrong canceltoken parameter')
            unless query?
                query = @searchResults.query
            if query? and query.length > 0
                @_search query, filters, cancelToken
            else
                sm.resolveImmediately()

        renderUnitsByCategoryList: (categoryList, queryParameters, cancelToken) ->
            itemIds = categoryList
                .split(',')
                .reduce((memo, value) ->
                    [type, id] = value.split ':'
                    if memo[type]
                        memo[type].push id
                    return memo
                , { service: [], service_node: [] })

            $.when @renderUnitsByServiceItems('service', itemIds.service, queryParameters, cancelToken),
                @renderUnitsByServiceItems('serviceNode', itemIds.service_node, queryParameters, cancelToken)

        renderUnitsByServiceNodes: (serviceNodeIdString, queryParameters, cancelToken) ->
            serviceNodeIds = serviceNodeIdString.split ','
            @renderUnitsByServiceItems 'serviceNode', serviceNodeIds, queryParameters, cancelToken

        renderUnitsByServiceItems: (type, serviceItemIds, queryParameters, cancelToken) ->
            itemConfiguration =
                service:
                    modelClass: models.Service
                    data: {}
                    analytics: 'addService'
                    addCommand: 'addService'
                serviceNode:
                    modelClass: models.ServiceNode
                    data:
                        include: 'ancestors'
                    analytics: 'addServiceNode'
                    addCommand: 'addServiceNode'

            @_unselectPosition()

            if serviceItemIds.length == 0
                return sm.resolveImmediately()

            console.assert(cancelToken?.constructor?.name == 'CancelToken', 'wrong canceltoken parameter')
            municipalityIds = queryParameters?.municipality?.split ','
            providerTypes = queryParameters?.provider_type?.split ','
            organizationUuid = queryParameters?.organization

            fetchPromises = serviceItemIds
                .map (id) -> new itemConfiguration[type].modelClass id: id
                # TODO: see if service item is being added or removed, then call corresponding app.request
                .map (serviceItem) ->
                    sm.withDeferred (deferred) ->
                        serviceItem.fetch
                            data: itemConfiguration[type].data
                            success: -> deferred.resolve serviceItem
                            error: -> deferred.resolve null

            return $.when(fetchPromises...)
                .done (serviceItems...) =>
                    commandPromises = serviceItems.map (serviceItem) =>
                        if serviceItem == null
                            return false
                        Analytics.trackCommand itemConfiguration[type].analytics, [serviceItem]
                        command = itemConfiguration[type].addCommand
                        return @[command](serviceItem, {organization: organizationUuid, municipality: municipalityIds, provider_type: providerTypes}, cancelToken)
                            .done -> true
                    return $.when commandPromises...

        _fetchDivisions: (divisionIds, callback) ->
            @divisions
                .setFilter 'ocd_id', divisionIds.join(',')
                .setFilter 'geometry', true
                .fetch success: callback

        _getLevel: (context, defaultLevel='none') ->
            context?.query?.level or defaultLevel

        _renderDivisions: (ocdIds, context) ->
            level = @_getLevel context, defaultLevel='none'
            sm.withDeferred (deferred) =>
                @_fetchDivisions ocdIds, =>
                    if level == 'none'
                        deferred.resolve()
                        return
                    if level != 'all'
                        @units.setFilter 'level', context.query.level
                    @units
                        .setFilter 'division', ocdIds.join(',')
                    opts =
                        data:
                            only: UNIT_MINIMAL_ONLY_FIELDS
                        success: =>
                            unless @units.fetchNext opts
                                @units.trigger 'finished'
                                deferred.resolve()
                    @units.fetch opts
                    @units

        showDivisions: (filters, statisticsPath ,cancelToken) ->
            @divisions.clearFilters()
            @divisions.setFilter 'geometry', true
            @divisions.setFilter 'type', 'statistical_district'
            for key, val of filters
                @divisions
                    .setFilter key, val
            options = {cancelToken, fetchType: 'data'}
            options.onPageComplete = => null
            cancelToken.activate()
            cancelToken.set 'cancelable', false
            @divisions.fetchPaginated(options).done =>
                options = {cancelToken, statistical_districts: @divisions.models.map (div) -> div.get('origin_id')}
                # Fetch statistics only when needed
                if ( _.isEmpty(@statistics.attributes) )
                    @statistics.fetch(options).done (data) =>
                        @divisions.trigger 'finished', cancelToken, statisticsPath
                else
                    @divisions.trigger 'finished', cancelToken, statisticsPath

        renderDivision: (municipality, divisionId, context) ->
            @_renderDivisions ["#{municipality}/#{divisionId}"], context
        renderMultipleDivisions: (_path, context) ->
            if context.query.ocdId.length > 0
                @_renderDivisions context.query.ocdId, context

        renderAddress: (municipality, street, numberPart, context) ->
            [newUri, newAddress] = GeocodeCleanup.cleanAddress {municipality, street, numberPart}
            if newUri
                {municipality, street, numberPart} = newAddress
                relative = newUri.relativeTo(newUri.origin())
                @router.navigate relative.toString(), replace: true
            level = @_getLevel context, defaultLevel='none'
            @level = level
            sm.withDeferred (deferred) =>
                SEPARATOR = /-/g
                slug = "#{municipality}/#{street}/#{numberPart}"
                positionList = models.PositionList.fromSlug municipality, street, numberPart
                l = appSettings.street_address_languages
                address_languages = _.object l, l
                @listenTo positionList, 'sync', (p, res, opts) =>
                    try
                        if p.length == 0
                            lang = opts.data.language
                            # If the street address slug isn't matching,
                            # the language is probably wrong.
                            # Try the possible address languages in order.
                            for address_language of address_languages
                                if lang != address_language
                                    lang = address_language
                                    delete address_languages[lang]
                                    break
                            if opts.data.language != lang
                                opts.data.language = lang
                                p.fetch data: opts.data
                            else
                                throw new Error 'Address slug not found', slug
                        else if p.length == 1
                            position = p.pop()
                        else if p.length > 1
                            exactMatch = p.filter (pos) ->
                                numberParts = numberPart.split SEPARATOR
                                letter = pos.get 'letter'
                                number_end = pos.get 'number_end'
                                if numberParts.length == 1
                                    return letter == null and number_end == null
                                letterMatch = -> letter and letter.toLowerCase() == numberParts[1].toLowerCase()
                                numberEndMatch = -> number_end and number_end == numberParts[1]
                                return letterMatch() or numberEndMatch()
                            if exactMatch.length != 1
                                throw new Error 'Too many address matches'
                            else
                                position = exactMatch[0]

                        if position?
                            slug = position.slugifyAddress()
                            newMunicipality = slug.split('/')[0]
                            if newMunicipality != municipality
                                # If the original slug was in the wrong language, run full
                                # command cycle including URL navigation to change the URL language.
                                # For example in Finland, the slug should be in Swedish if the UI is in Swedish,
                                # otherwise in Finnish (the default).
                                @selectPosition(position).done =>
                                    @router.navigate "address/#{slug}", replace: true
                            else
                                @selectPosition position
                    catch err
                        addressInfo =
                            address: slug

                        Raven.captureException err, {extra: addressInfo}
                    @_checkLocationHash() unless sm.getIeVersion() and sm.getIeVersion() < 10
                    deferred.resolve()

        showAllUnits: (level) ->
            unless level?
                level = @level

            transformedBounds = @mapProxy.getTransformedBounds()
            bboxes = transformedBounds.map (bbox) ->
                "#{bbox[0][0]},#{bbox[0][1]},#{bbox[1][0]},#{bbox[1][1]}"

            @addUnitsWithinBoundingBoxes bboxes, level

        renderHome: (path, context) ->
            unless (not path? or
                path == '' or
                (path instanceof Array and path.length = 0))
                    context = path
            level = @_getLevel context, defaultLevel='none'
            @reset()
            sm.withDeferred (d) =>
                d.resolve afterMapInit: =>
                    if level != 'none'
                        @showAllUnits level

        renderSearch: (path, opts, cancelToken) ->
            unless opts.query?.q?
                return
            filters = {}
            for filter in ['municipality', 'service_node']
                value = opts.query?[filter]
                if value?
                    filters[filter] = value
            @search opts.query.q, filters, cancelToken

        _matchResourceUrl: (path) ->
            match = path.match /^([0-9]+)/
            if match?
                match[0]

        _checkLocationHash: () ->
            hash = window.location.hash.replace(/^#!/, '#');
            if hash
                app.vent.trigger 'hashpanel:render', hash

        renderUnit: (path, opts, cancelToken) ->
            console.assert(cancelToken?.constructor?.name == 'CancelToken', 'wrong canceltoken parameter')
            id = @_matchResourceUrl path
            if id?
                def = $.Deferred()
                @renderUnitById(id, true).done (unit) =>
                    def.resolve
                        afterMapInit: =>
                            if appSettings.is_embedded
                                @selectUnit unit
                            else
                                @highlightUnit unit
                            @_checkLocationHash() unless sm.getIeVersion() and sm.getIeVersion() < 10
                return def.promise()

            query = opts.query

            if query?.service
                return renderUnitsByOldServiceId query, @, cancelToken

            if query?.service_node
                return @renderUnitsByServiceNodes query.service_node, query, cancelToken
                    .done (results...) ->
                        unless _.find results, _.identity
                            # There were no successful serviceNode retrievals
                            # (all results are 'false') -> display message to user.
                            app.commands.execute 'displayMessage', 'search.no_results'

            if query?.category
                return @renderUnitsByCategoryList query.category, query, cancelToken
                    .done (results...) ->
                        if not _.some results, _.identity
                            app.commands.execute 'displayMessage', 'search.no_results'

        _getRelativeUrl: (uri) ->
            uri.toString().replace /[a-z]+:\/\/[^/]*\//, '/'
        _setQueryParameter: (key, val) ->
            uri = URI document.location.href
            uri.setSearch key, val
            url = @_getRelativeUrl uri
            @router.navigate url
        _removeQueryParameter: (key) ->
            uri = URI document.location.href
            uri.removeSearch key
            url = @_getRelativeUrl uri
            @router.navigate url

        addDataLayer: (layer, layerId, leafletId) ->
            background = p13n.get 'map_background_layer'
            if background in ['servicemap', 'accessible_map']
                @dataLayers.add
                    dataId: layerId
                    layerName: layer
                    leafletId: leafletId
            else
                p13n.setMapBackgroundLayer 'servicemap'
            @selectedDataLayers.set layer, layerId
            @_setQueryParameter layer, layerId
        removeDataLayer: (layer) ->
            @dataLayers.remove (@dataLayers.where
                layerName: layer
            )
            @selectedDataLayers.unset layer
            @_removeQueryParameter layer

        displayMessage: (messageId) ->
            @informationalMessage.set 'messageKey', messageId

        displayNotification: (title, message) ->
            show = true
            @notificationMessage.set {show, title, message}

        requestTripPlan: (from, to, opts, cancelToken) ->
            @route.requestPlan from, to, opts, cancelToken

