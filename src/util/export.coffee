define ['URI', 'cs!app/models'], (URI, models) ->

    { UnitList } = models

    modelsToApiCall = (models) =>

        { selectedUnits, selectedServices, searchResults, units } = models

        if selectedUnits.isSet()
            return selectedUnits.first().url()
        else if selectedServices.isSet()
            url = (new UnitList()).url()
            return URI(url).addSearch
                service: selectedServices.pluck('id').join(',')
        else if searchResults.isSet()
            return searchResults.url()
        return null

    exportLink = (format, models) =>
        if format not in ['kml', 'json']
            return null
        url = modelsToApiCall(models)
        return null unless url
        uri = URI url
        uri.addSearch format: format
        uri.toString()

    return exportLink: exportLink
