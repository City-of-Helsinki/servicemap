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
            development:
                options:
                    paths: ['styles']
                files:
                    'static/css/servicemap.css': 'styles/servicemap.less'
                    'static/css/bootstrap.css': 'styles/bootstrap/bootstrap.less'

        watch:
            files: [
                'Gruntfile.coffee'
                'src/*.coffee'
                'server-src/*.coffee'
            ]
            tasks: 'default'

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
    grunt.loadNpmTasks 'grunt-express-server'

    grunt.registerTask 'default', ['coffee', 'less']
    grunt.registerTask 'server', ['coffee', 'less', 'express', 'watch']
