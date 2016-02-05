define ['URI', 'cs!app/models'], (URI, model) ->

    modelsToSelectionType = (models) =>
        { selectedUnits, selectedServices, searchResults, units } = models

        if selectedUnits.isSet()
            return 'single'
        else if selectedServices.isSet()
            return 'service'
        else if searchResults.isSet()
            return 'search'
        else if units.isSet() and units.hasFilters()
            unless units.filters.bbox?
                if units.filters.division?
                    return 'division'
                else if units.filters.distance?
                    return 'distance'
        return 'unknown'

    modelsToExportSpecification = (models) =>
        { selectedUnits, selectedServices, searchResults, units, divisions } = models
        key = modelsToSelectionType models
        specs = key: key, size: units.size()
        _.extend specs, switch key
            when 'single'
                unit = selectedUnits.first()
                url: unit.url()
                size: 1
                details: [unit.getText 'name']
            when 'service'
                unitList = new model.UnitList()
                unitList.setFilter 'service', selectedServices.pluck('id').join(',')
                url: unitList.url()
                details: selectedServices.map (s) => s.getText 'name'
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

    exportSpecification = (format, models) =>
        if format not in ['kml', 'json']
            return null
        specs = modelsToExportSpecification models
        url = specs.url
        if url
            uri = URI url
            uri.addSearch format: format
            specs.url = uri.toString()
        specs

    exportSpecification: exportSpecification
