checkForImports = (details, shouldIncludeCallback) ->
    fs = require("fs")
    path = require("path")
    async = require("async")
    checkFileForModifiedImports = async.memoize((filepath, fileCheckCallback) ->
        fs.readFile filepath, "utf8", (error, data) ->
            checkNextImport = ->
                if (match = regex.exec(data)) is null # all @import files has been checked.
                    return fileCheckCallback(false)
                importFilePath = path.join(directoryPath, match[1] + ".less")
                fs.exists importFilePath, (exists) ->
                    # @import file does not exists.
                    return checkNextImport() unless exists # skip to next
                    fs.stat importFilePath, (error, stats) ->
                        if stats.mtime > details.time
                            # @import file has been modified, -> include it.
                            fileCheckCallback true
                        else
                            # @import file has not been modified but, lets check the @import's of this file.
                            checkFileForModifiedImports importFilePath, (hasModifiedImport) ->
                                if hasModifiedImport
                                    fileCheckCallback true
                                else
                                    checkNextImport()

            directoryPath = path.dirname(filepath)
            regex = /@import (?:\([^)]+\) )?"(.+?)(\.less)?"/g
            match = undefined
            checkNextImport()
    )

    # only add override behavior to less tasks.
    if details.task is "less"
        checkFileForModifiedImports details.path, (found) ->
            shouldIncludeCallback found
            return
    else
        shouldIncludeCallback false
    return

module.exports = (grunt) ->
    loadLocalTasks = ->
        requirejs = require 'requirejs'
        requirejs.config
            baseUrl: __dirname
            paths:
                app: 'static/js'
            nodeRequire: require

        cssTemplate = """
                .service-<%= hover %><%= background %>color-<%= light %><%= key %><%= hoverPc %> {
                    <%= background %>color: <%= color %> !important;
                }
                """

        grunt.registerMultiTask "coffee2css", "Generate css classes from colors in a coffeescript file.", ->
            ColorMatcher = requirejs 'app/color'
            grunt.log.writeln "Generating CSS for service colors."
            options = @options()
            cssOutput = ''
            for background in [true, false]
                for pseudo in ['hover', 'focus', '']
                    for light in [true, false]
                        cssOutput += "\n" + (grunt.template.process(
                            cssTemplate,
                            data:
                                key: key
                                color: if light then ColorMatcher.rgba(r, g, b, "0.30") else ColorMatcher.rgb(r, g, b)
                                background: if background then "background-" else ""
                                light: if light then "light-" else ""
                                hover: if pseudo == '' then "" else "hover-"
                                hoverPc: if pseudo != '' then ":" + pseudo) for own key, [r, g, b] of ColorMatcher.serviceColors).join "\n"

            grunt.file.write options.output, cssOutput + "\n"
            return

    grunt.initConfig
        pkg: '<json:package.json>'
        coffee:
            client:
                options:
                    sourceMap: true
                expand: true
                cwd: 'src'
                flatten: false
                src: ['*.coffee', 'views/*.coffee']
                dest: 'static/js/'
                ext: '.js'
            server:
                expand: true
                cwd: 'server-src'
                src: ['*.coffee']
                dest: 'server-js/'
                ext: '.js'
            tasks:
                expand: true
                cwd: 'tasks-src'
                src: ['*.coffee']
                dest: 'tasks/'
                ext: '.js'
        dalek:
            all:
                src: ['test/test.coffee']
        less:
            main:
                options:
                    paths: ['styles']
                files:
                    'static/css/servicemap.css': 'styles/servicemap.less'
                    'static/css/bootstrap.css': 'styles/bootstrap/bootstrap.less'
                    'static/css/servicemap_ie.css': 'styles/servicemap_ie.less'
                    'static/css/servicemap_ie9.css': 'styles/servicemap_ie9.less'
        'i18next-yaml':
            fi:
                src: 'locales/*.yaml'
                dest: 'static/locales/fi.json'
                options:
                    language: 'fi'
            sv:
                src: 'locales/*.yaml'
                dest: 'static/locales/sv.json'
                options:
                    language: 'sv'
            en:
                src: 'locales/*.yaml'
                dest: 'static/locales/en.json'
                options:
                    language: 'en'
        jade:
            compile:
                options:
                    client: true
                files:
                    'static/templates.js': ['views/templates/**/*.jade']
        newer:
            options:
                override: checkForImports

        coffee2css:
            color_mapping:
                options:
                    output: 'static/css/colors.css'
                files:
                    'static/css/colors.css': 'src/color.coffee'
        watch:
            express:
                files: [
                    'Gruntfile.coffee'
                    'server-src/*.coffee'
                    'config/*.yml'
                ]
                options:
                    spawn: false
                tasks: ['coffee:server', 'express']
            'coffee-client':
                files: [
                    'src/*.coffee',
                    'src/views/*.coffee'
                ]
                tasks: 'newer:coffee:client'
            coffee2css:
                files: [
                    'Gruntfile.coffee'
                    'src/color.coffee'
                ]
                tasks: 'coffee2css'
            less:
                files: [
                    'styles/**/*.less'
                ]
                tasks: 'newer:less'
            i18n:
                files: [
                    'locales/*.yaml'
                ]
                tasks: 'i18next-yaml'
            jade:
                files: [
                    'views/templates/**/*.jade'
                ]
                tasks: 'jade'
            livereload:
                options:
                    livereload: true
                files: ['static/**/*.js', 'static/**/*.css']

        express:
            options:
                port: 9001
                spawn: true
            dev:
                options:
                    script: 'server-js/dev.js'

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-express-server'
    grunt.loadNpmTasks 'grunt-i18next-yaml'
    grunt.loadNpmTasks 'grunt-newer'
    grunt.loadNpmTasks('grunt-dalek');

    loadLocalTasks()

    grunt.registerTask 'default', ['newer:coffee', 'newer:less', 'newer:i18next-yaml', 'newer:jade', 'newer:coffee2css']
    grunt.registerTask 'server', ['default', 'express', 'watch']
    grunt.registerTask 'tasks', ['coffee:tasks']
    grunt.registerTask 'test', ['dalek:all']
