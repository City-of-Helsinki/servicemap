define ->

    extractCommandDetails = (command, parameters) ->
        name = undefined
        value = undefined
        switch command
            when 'addServiceNode'
                serviceModel = parameters[0]
                if serviceModel?
                    serviceName = serviceModel.get('name')?.fi
                    if serviceName? then name = serviceName + " "
                    name += "#{serviceModel.get 'id'}"
            when 'setProfileCity', 'setProfileMobility', 'setProfileSenses'
                name = parameters[0]
                value = parameters[1]
        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
