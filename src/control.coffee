define ['jquery', 'backbone.marionette', 'app/base', 'app/models'],
       ($, Marionette, sm, models) ->

    class BaseControl extends Marionette.Controller
        initialize: (appModels) ->
            # Units currently on the map
            @units = appModels.units
            # Services in the cart
            @services = appModels.selectedServices
            # Selected units (always of length one)
            @selectedUnits = appModels.selectedUnits
            @selectedPosition = appModels.selectedPosition
            @searchResults = appModels.searchResults
            @selectedDivision = appModels.selectedDivision

        setUnits: (units, filter) ->
            @services.set []
            @_setSelectedUnits()
            @units.reset units.toArray()
            if filter?
                @units.setFilter filter, true
            else
                @units.clearFilters()
            # Current cluster based map logic
            # requires batch reset signal.

        setUnit: (unit) ->
            @services.set []
            @units.reset [unit]

        getUnit: (id) ->
            return @units.get id

        addUnitsWithinBoundingBoxes: (bboxStrings) ->
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
                unitList = new models.UnitList()
                opts = success: (coll, resp, options) =>
                    if unitList.length
                        @units.add unitList.toArray()
                    unless unitList.fetchNext(opts)
                        unitList.trigger 'finished',
                            keepViewport: true
                unitList.pageSize = PAGE_SIZE
                unitList.setFilter 'bbox', bboxString
                layer = p13n.get 'map_background_layer'
                unitList.setFilter 'bbox_srid', if layer in ['servicemap', 'accessible_map'] then 3067 else 3879
                unitList.setFilter 'only', 'name,location,root_services'
                # Default exclude filter: statues, wlan hot spots
                unitList.setFilter 'exclude_services', '25658,25538'
                @listenTo unitList, 'finished', =>
                    getBbox _.rest(bboxStrings)
                unitList.fetch(opts)
            getBbox(bboxStrings)

        toggleDivision: (division) =>
            @_clearRadius()
            old = @selectedDivision.value()
            if old? then old.set 'selected', false
            if division == old
                @selectedDivision.clear()
            else
                @selectedDivision.wrap division
                division.set 'selected', true

        renderUnitById: (id) ->
            deferred = $.Deferred()
            unit = new Models.Unit id: id
            unit.fetch
                data:
                    include: 'department,municipality'
                success: =>
                    deferred.resolve unit
            deferred.promise()

        selectPosition: (position) ->
            @clearSearchResults()
            @_setSelectedUnits()
            previous = @selectedPosition.value()
            if previous?.get('radiusFilter')?
                @units.reset []
                @units.clearFilters()
            if position == previous
                @selectedPosition.trigger 'change:value', @selectedPosition
            else
                @selectedPosition.wrap position
            sm.resolveImmediately()

        setRadiusFilter: (radius) ->
            @services.reset [], skip_navigate: true
            @units.reset []
            @units.clearFilters()
            @units.overrideComparatorKeys = [
                'distance_precalculated',
                'alphabetic',
                'alphabetic_reverse']
            @units.setComparator 'distance_precalculated'
            if @selectedPosition.isEmpty()
                return
            pos = @selectedPosition.value()
            pos.set 'radiusFilter', radius

            unitList = new models.UnitList [], pageSize: PAGE_SIZE
                .setFilter 'only', 'name,location,root_services'
                .setFilter 'include', 'services,accessibility_properties'
                .setFilter 'lat', pos.get('location').coordinates[1]
                .setFilter 'lon', pos.get('location').coordinates[0]
                .setFilter 'distance', radius
            opts =
                success: =>
                    @units.add unitList.toArray(), merge: true
                    @units.setFilter 'distance', radius
                    unless unitList.fetchNext opts
                        @units.trigger 'finished', refit: true
            unitList.fetch opts

        _addService: (service) ->
            @_clearRadius()
            @_setSelectedUnits()
            @services.add service
            if @services.length == 1
                # Remove possible units
                # that had been added through
                # other means than service
                # selection.
                @units.reset []
                @units.clearFilters()
                @units.setDefaultComparator()
                @clearSearchResults()

            if service.has 'ancestors'
                ancestor = @services.find (s) ->
                    s.id in service.get 'ancestors'
                if ancestor?
                    @removeService ancestor
            @_fetchServiceUnits service

        _fetchServiceUnits: (service) ->
            unitList = new models.UnitList [], pageSize: PAGE_SIZE, setComparator: true
                .setFilter('service', service.id)
                .setFilter('only', 'name,location,root_services')
                .setFilter('include', 'services,accessibility_properties')

            municipality = p13n.get 'city'
            if municipality
                unitList.setFilter 'municipality', municipality

            opts =
                # todo: re-enable
                #spinnerTarget: spinnerTarget
                success: =>
                    @units.add unitList.toArray(), merge: true
                    service.get('units').add unitList.toArray()
                    unless unitList.fetchNext opts
                        @units.overrideComparatorKeys = ['alphabetic', 'alphabetic_reverse', 'distance']
                        @units.setDefaultComparator()
                        @units.trigger 'finished', refit: true
                        service.get('units').trigger 'finished'

            unitList.fetch opts

        addService: (service) ->
            if service.has('ancestors')
                @_addService service
            else
                sm.withDeferred (deferred) =>
                    service.fetch
                        data: include: 'ancestors'
                        success: =>
                            @_addService(service).done =>
                                deferred.resolve()
        _search: (query) ->
            @_clearRadius()
            @selectedPosition.clear()
            @clearUnits all: true
            if @searchResults.query == query
                @searchResults.trigger 'ready'
                return

            if 'search' in _(@units.filters).keys()
                @units.reset []

            unless @searchResults.isEmpty()
                @searchResults.reset []
            opts =
                success: =>
                    if _paq?
                        _paq.push ['trackSiteSearch', query, false, @searchResults.models.length]
                    @units.add @searchResults.filter (r) ->
                        r.get('object_type') == 'unit'
                    @units.setFilter 'search', true
                    unless @searchResults.fetchNext opts
                        @searchResults.trigger 'ready'
                        @units.trigger 'finished'
                        @services.set []
            opts = @searchResults.search query, opts

        search: (query) ->
            unless query?
                query = @searchResults.query
            if query? and query.length > 0
                @_search query
            sm.resolveImmediately()

        renderUnitsByServices: (serviceIdString) ->
            serviceIds = serviceIdString.split ','
            deferreds = _.map serviceIds, (id) =>
                @addService new models.Service id: id
            return $.when deferreds...

        renderAddress: (municipality, street, numberPart) ->
            sm.withDeferred (deferred) =>
                SEPARATOR = /-/g
                slug = "#{municipality}/#{street}/#{numberPart}"
                positionList = models.PositionList.fromSlug municipality, street, numberPart
                @listenTo positionList, 'sync', (p) =>
                    if p.length == 0
                        throw new Error 'Address slug not found'
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
                        position = exactMatch.pop()
                    @selectPosition position
                    deferred.resolve()
