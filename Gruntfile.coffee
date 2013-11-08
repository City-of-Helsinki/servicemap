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

    grunt.registerTask 'default', ['coffee']
    grunt.registerTask 'server', ['coffee', 'connect', 'watch']
