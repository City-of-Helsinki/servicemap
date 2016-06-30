define ->

    extractCommandDetails = (command, parameters) ->
        name = undefined
        value = undefined
        switch command
            when 'addService'
                name = parameters[0]?.get('id') or parameters[0]
        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
