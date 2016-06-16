define [
        'leaflet'
    ]
, (
    L
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

    HEATMAP_DATASETS: ['ika0-6',
        'ika7-12',
        'ika13-17',
        'ika18-29',
        'ika30-64',
        'ika65-',
        'asyht',
        'suom',
        'ruots',
        'muunkiel']

    getStrata: ->
        HEATMAP_DATASETS

    dataLayerPath: (id) ->
        layerFmt = 'png'
        # "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/popdensity:#{id}@ETRS-TM35FIN@#{layerFmt}/{z}/{x}/{y}.#{layerFmt}"
        # "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:alltest&FORMAT=image%2Fpng&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:15&TILEROW=26700&TILECOL=14500&STYLE=popdensity:all_density_suom"
        "http://geoserver.hel.fi/geoserver/gwc/service/wmts/?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=popdensity:alltest&FORMAT=image%2F#{layerFmt}&TILEMATRIXSET=ETRS-TM35FIN&TILEMATRIX=ETRS-TM35FIN:{z}&TILEROW={y}&TILECOL={x}"