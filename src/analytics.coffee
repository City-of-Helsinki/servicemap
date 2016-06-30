define ->

    extractCommandDetails = (command, parameters) ->
        name = undefined
        value = undefined
        switch command
            when 'addService'
                serviceModel = parameters[0]
                name = serviceModel?.get('name')?.fi or serviceModel
                value = serviceModel?.get('id') or serviceModel
        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
