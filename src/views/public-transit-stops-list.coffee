define (require) ->
    _ = require 'underscore'

    base = require 'cs!app/views/base'
    {routeCompare, typeToName} = require 'cs!app/util/transit'
    PublicTransitStopView = require 'cs!app/views/public-transit-stop'

    class PublicTransitStopsListView extends base.SMLayout
        template: 'public-transit-stops-list'

        regions:
            stopContent: '.stop-content'

        events: ->
            'click .stop-wrapper': 'selectStop'

        serializeData: ->
            items = super().items
                .map (stop) -> _.extend stop, { vehicleTypeName: typeToName[stop.vehicleType] }

            items
                .filter (stop) -> !!stop.patterns
                .forEach (stop) ->
                    stop.patterns = _.uniq stop.patterns, (pattern) -> pattern.route?.shortName
                    stop.patterns.sort routeCompare

            { items }

        selectStop: (event) ->
            event.preventDefault()
            stopId = $(event.currentTarget).data('stop-id')
            stop = @collection.get stopId

            if not stop
                console.error "Cannot find stop with id #{stopId} in cluster"
                return

            stopView = new PublicTransitStopView { stop }

            @listenToOnce stop, 'change', =>
                @stopContent.show stopView
                @$('.list-content').hide()
