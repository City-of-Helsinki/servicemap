define ->

    extractCommandDetails = (command, parameters) ->
        name = undefined
        value = undefined
        switch command
            when 'addService'
                serviceModel = parameters[0]
                if serviceModel?
                    serviceName = serviceModel.get('name')?.fi
                    if serviceName? then name = serviceName + " "
                    name += "#{serviceModel.get 'id'}"
        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
