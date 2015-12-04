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
    'jade:client'
    'i18next-yaml'
    # TODO: Fix the coffee2css task, it doesn't currently work
    #'coffee2css'
  ]

  grunt.registerTask 'dev', [
    'build'
    'less:dev'
    'copy:images'
  ]

  grunt.registerTask 'dist', [
    'build'
    'less:dist'
    'imagemin:dist'
    'requirejs'
  ]

  grunt.registerTask 'publish', [
    'clean:static'
    'copy:publish'
  ]

  grunt.registerTask 'start', [
    'dev'
    'publish'
    'coffee:server'
    'express:dev'
    'watch'
  ]
