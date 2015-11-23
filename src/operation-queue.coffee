define ->

    class OperationQueue
        constructor: ->
            @startOperation()
        startOperation: ->
            @xhrObjects = []
            @status = 'init'
        addRequest: (xhr) ->
            @xhrObjects.push xhr
            @status = 'inprogress'
        cancelOperation: ->
            @status = 'cancelled'
            for xhr in @xhrObjects
                xhr.abort()
            app.commands.execute 'cancel'

    return new OperationQueue()
