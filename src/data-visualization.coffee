define [
    'leaflet',
    'cs!app/p13n'
    ]
, (
    L,
    p13n
) ->

# HEATMAP_DATASETS = [{id: 'age0-6', style: 'dummy'},
#                     {id: 'age7-12', style: 'dummy'},
#                     {id: 'age13-17', style: 'dummy'},
#                     {id: 'age18-29', style: 'dummy'},
#                     {id: 'age30-64', style: 'dummy'},
#                     {id: 'age65-', style: 'dummy'},
#                     {id: 'all', style: 'dummy'},
#                     {id: 'finnish', style: 'dummy'},
#                     {id: 'swedish', style: 'dummy'},
#                     {id: 'other_lang', style: 'dummy'}]

# HEATMAP_DATASETS: ['age0-6',
#                     'age7-12',
#                     'age13-17',
#                     'age18-29',
#                     'age30-64',
#                     'age65-',
#                     'all',
#                     'finnish',
#                     'swedish',
#                     'other_lang']


    class DataVisualization
        HEATMAP_DATASETS =
            'all':              'RTV201412'
            'age_0-6':          'RTV201412'
            'age_7-12':         'RTV201412'
            'age_13-17':        'RTV201412'
            'age_18-29':        'RTV201412'
            'age_30-64':        'RTV201412'
            'age_over_65':      'RTV201412'
            'language_fi':      'RTV201412'
            'language_sv':      'RTV201412'
            'language_other':   'RTV201412'
        DATA_LAYERS = Object.keys HEATMAP_DATASETS
        getStrata: ->
            HEATMAP_DATASETS

        dataLayerPath: (id) ->
            layerFmt = 'png'
            # "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/popdensity:#{id}@ETRS-TM35FIN@#{layerFmt}/{z}/{x}/{y}.#{layerFmt}"
            # "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:alltest&FORMAT=image%2Fpng&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:15&TILEROW=26700&TILECOL=14500&STYLE=popdensity:all_density_suom"
            "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:#{HEATMAP_DATASETS[id]}&FORMAT=image%2F#{layerFmt}&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:{z}&TILEROW={y}&TILECOL={x}"

        getDataLayers: ->
            DATA_LAYERS

    new DataVisualization