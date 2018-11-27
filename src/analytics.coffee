define ->
    extractCommandDetails = (command, parameters) ->
        getName = (serviceItemModel) ->
            if not serviceItemModel?
                return

            serviceItemName = serviceItemModel.get('name')?.fi
            serviceItemId = serviceItemModel.get 'id'

            "#{serviceItemName} #{serviceItemId}".trim()

        name = undefined
        value = undefined

        switch command
            when 'addServiceNode'
                name = getName parameters[0]
            when 'addService'
                name = getName parameters[0]

        return {
            name: name
            value: value
        }

    trackCommand: (command, parameters) ->
        if _paq?
            {name, value} = extractCommandDetails command, parameters
            _paq.push ['trackEvent', 'Command', command, name, value]
