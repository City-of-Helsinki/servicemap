define ->
    class DataVisualization
        # Data layers as in name: map_id
        HEATMAP_DATASETS =
            'all':              'asyht'
            'age_0-6':          'ika0_6'
            'age_7-12':         'ika7_12'
            'age_13-17':        'ika13_17'
            'age_18-29':        'ika18_29'
            'age_30-64':        'ika30_64'
            'age_over_65':      'ika65_'
            'language_fi':      'suom'
            'language_sv':      'ruots'
            'language_other':   'muunkiel'
        DATA_LAYERS = Object.keys HEATMAP_DATASETS
        getStrata: ->
            HEATMAP_DATASETS

        dataLayerPath: (id) ->
            layerFmt = 'png'
            # "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/popdensity:#{id}@ETRS-TM35FIN@#{layerFmt}/{z}/{x}/{y}.#{layerFmt}"
            # "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:alltest&FORMAT=image%2Fpng&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:15&TILEROW=26700&TILECOL=14500&STYLE=popdensity:all_density_suom"
            unless HEATMAP_DATASETS[id]
                return ''
            "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:alltest&style=popdensity:all_density_#{HEATMAP_DATASETS[id]}&FORMAT=image%2F#{layerFmt}&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:{z}&TILEROW={y}&TILECOL={x}"

        getDataLayers: ->
            DATA_LAYERS

    new DataVisualization
