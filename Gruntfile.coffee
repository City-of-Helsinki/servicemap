module.exports = (grunt) ->
    grunt.initConfig
        pkg: '<json:package.json>'
        coffee:
            glob_to_multiple:
                expand: true
                cwd: 'src'
                src: ['*.coffee']
                dest: 'static/js/'
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
            ]
            tasks: 'default'

        connect:
            server:
                options:
                    port: 9001
                    base: "static"

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-connect'
    grunt.loadNpmTasks 'grunt-contrib-less'

    grunt.registerTask 'default', ['coffee', 'less']
    grunt.registerTask 'server', ['coffee', 'less', 'connect', 'watch']
