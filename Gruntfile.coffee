module.exports = (grunt) ->

  path = require 'path'

  require('time-grunt')(grunt)

  require('jit-grunt')(grunt, {
      express: 'grunt-express-server'
  })

  require('load-grunt-tasks')(grunt, {
    pattern: ['main-bower-files']
  })

  require('load-grunt-config')(grunt, {
    configPath: path.join __dirname, 'grunt/config'
    data:
      assets: 'assets'
      build: '.build'
      locales: 'locales'
      src: 'src'
      static: 'static'
      styles: 'styles'
      views: 'views'
    jitGrunt: true
  })

  grunt.loadTasks './grunt/tasks'

  grunt.registerTask 'build', [
    'clean:build'
    'bower:client'
    'copy:app'
    'copy:fonts'
    'copy:vendor'
    'coffee2css:colors'
    'i18next-yaml'
  ]

  grunt.registerTask 'dev', [
    'build'
    'less:dev'
    'jade:dev'
    'copy:images'
  ]

  grunt.registerTask 'dist', [
    'build'
    'less:dist'
    'jade:dist'
    'imagemin:dist'
    'requirejs'
  ]

  grunt.registerTask 'publish', [
    'clean:static'
    'copy:publish'
  ]

  grunt.registerTask 'test', [
    # TODO: Configure this
  ]

  grunt.registerTask 'start', [
    'dev'
    'publish'
    'coffee:server'
    'express:dev'
    'watch'
  ]
