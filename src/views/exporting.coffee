define ['URI', 'app/views/base', 'app/p13n'], (URI, base, p13n) ->

    class ExportingView extends base.SMLayout
        template: 'exporting'
        events:
            'click .exporting-button': 'exportEmbed'
        exportEmbed: (ev) ->
            EXPORT_PREVIEW_HOST = 'localhost'
            url = URI window.location.href
            url.host EXPORT_PREVIEW_HOST
            query = url.search true
            query.bbox = @getMapBoundsBbox()
            background = p13n.get('map_background_layer')
            if background not in ['servicemap', 'guidemap']
                query.map = background
            url.search query
            window.location.href = url.toString()
        getMapBoundsBbox: ->
            # TODO: don't break architecture thusly
            __you_shouldnt_access_me_like_this = window.mapView.map
            wrongBbox = __you_shouldnt_access_me_like_this.getBounds().toBBoxString().split ','
            rightBbox = _.map [1,0,3,2], (i) -> wrongBbox[i].slice(0,8)
            rightBbox.join ','
