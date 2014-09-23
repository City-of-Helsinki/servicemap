requirejs_config =
    baseUrl: app_settings.static_path + 'vendor'
    paths:
        test: '../js/test'
        app: '../js'
requirejs.config requirejs_config

window.get_ie_version = ->
    is_internet_explorer = ->
        window.navigator.appName is "Microsoft Internet Explorer"
    if not is_internet_explorer()
        return false
    matches = new RegExp(" MSIE ([0-9]+)\\.([0-9])").exec window.navigator.userAgent
    return parseInt matches[1]

BG_COLOR = 'rgb(80,180,180)'

define 'canvas_test', ['app/draw'], (draw) ->
    SIZE = 40
    p = new draw.Plant SIZE, 'rgb(255,200,100)', 13200,
        rotation = 90
    canvas = document.getElementById 'main-canvas'
    width = p.get_width() + 2
    height = SIZE + 2

    canvas.style.width = width
    canvas.style.height = height 
    canvas.width = width
    canvas.height = height

    console.log(p.get_anchor())
    
    ctx = canvas.getContext '2d'
    ctx.fillStyle = '#66aaaa'
    ctx.fillRect 0, 0, width, height;
    p.draw ctx
