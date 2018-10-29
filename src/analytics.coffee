define ->

    extractCommandDetails = (command, parameters) ->
        getName = (serviceItemModel) ->
            if serviceItemModel?
                serviceName = serviceItemModel.get('name')?.fi
                serviceId = serviceItemModel.get 'id'
                return [serviceName, serviceId]
                    .filter(_.identity)
                    .join(' ')

        name = undefined
        value = undefined

        switch command
            when 'addServiceNode'
                serviceNode = parameters[0]
                name = getName serviceNode
            when 'addService'
                service = parameters[0]
                name = getName service

        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
