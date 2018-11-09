define (require) ->
    URI   = require 'URI'

    models = require 'cs!app/models'

    modelsToSelectionType = (appModels) =>
        { selectedUnits, selectedServices, selectedServiceNodes, searchResults, units } = appModels

        if selectedUnits.isSet()
            return 'single'
        else if selectedServices.isSet()
            return 'service'
        else if selectedServiceNodes.isSet()
            return 'serviceNode'
        else if searchResults.isSet()
            return 'search'
        else if units.isSet() and units.hasFilters()
            unless units.filters.bbox?
                if units.filters.division?
                    return 'division'
                else if units.filters.distance?
                    return 'distance'
        return 'unknown'

    modelsToExportSpecification = (appModels) =>
        { selectedUnits, selectedServices, selectedServiceNodes, searchResults, units, divisions } = appModels
        key = modelsToSelectionType appModels
        specs = key: key, size: units.size()

        # FIXME 2018-11-09 services and service nodes need to be exported together
        _.extend specs, switch key
            when 'single'
                unit = selectedUnits.first()

                url: unit.url()
                size: 1
                details: [unit.getText 'name']
            when 'service'
                unitList = new models.UnitList()
                unitList.setFilter 'service', selectedServices.pluck('id').join(',')

                url: unitList.url()
                details: selectedServices.map (service) => service.getText 'name'
            when 'serviceNode'
                unitList = new models.UnitList()
                unitList.setFilter 'service_node', selectedServiceNodes.pluck('id').join(',')

                key: 'service'
                url: unitList.url()
                details: selectedServiceNodes.map (s) => s.getText 'name'
            when 'search'
                details: [searchResults.query]
                url: searchResults.url()
            when 'division'
                details: divisions.map (d) => d.getText 'name'
                url: units.url()
            when 'distance'
                details: []
                url: units.url()
            else
                url: null

    exportSpecification = (format, appModels) =>
        if format not in ['kml', 'json']
            return null
        specs = modelsToExportSpecification appModels
        url = specs.url
        if url
            uri = URI url
            uri.addSearch format: format
            specs.url = uri.toString()
        specs

    exportSpecification: exportSpecification
