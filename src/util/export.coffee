define ['URI', 'cs!app/models'], (URI, model) ->

    modelsToApiUrl = (models) =>
        { selectedUnits, selectedServices, searchResults, units } = models

        if selectedUnits.isSet()
            return selectedUnits.first().url()

        else if selectedServices.isSet()
            unitList = new model.UnitList()
            unitList.setFilter 'service', selectedServices.pluck('id').join(',')
            return unitList.url()

        else if searchResults.isSet()
            return searchResults.url()

        else if units.isSet() and units.hasFilters()
            unless units.filters.bbox?
                return units.url()

        return null

    exportLink = (format, models) =>
        if format not in ['kml', 'json']
            return null
        url = modelsToApiUrl(models)
        return null unless url
        uri = URI url
        uri.addSearch format: format
        uri.toString()

    return exportLink: exportLink
