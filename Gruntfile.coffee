module.exports = (grunt) ->
    grunt.initConfig
        pkg: '<json:package.json>'
        coffee:
            client:
                expand: true
                cwd: 'src'
                src: ['*.coffee']
                dest: 'static/js/'
                ext: '.js'
            server:
                expand: true
                cwd: 'server-src'
                src: ['*.coffee']
                dest: 'server-js/'
                ext: '.js'
        less:
            main:
                options:
                    paths: ['styles']
                files:
                    'static/css/servicemap.css': 'styles/servicemap.less'
                    'static/css/bootstrap.css': 'styles/bootstrap/bootstrap.less'
        'i18next-yaml':
            fi:
                src: 'locales/*.yaml'
                dest: 'static/locales/fi.json'
                options:
                    language: 'fi'
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
                    'static/templates.js': ['views/templates/*.jade']

        watch:
            'coffee-server':
                files: [
                    'Gruntfile.coffee'
                    'server-src/*.coffee'
                ]
                tasks: 'coffee:server'
            'coffee-client':
                files: [
                    'src/*.coffee'
                ]
                tasks: 'coffee:client'
            less:
                files: [
                    'styles/*.less'
                ]
                tasks: 'less'
            i18n:
                files: [
                    'locales/*.yaml'
                ]
                tasks: 'i18next-yaml'
            jade:
                files: [
                    'views/templates/*.jade'
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

    grunt.registerTask 'default', ['coffee', 'less', 'i18next-yaml']
    grunt.registerTask 'server', ['default', 'express', 'watch']
