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
    'copy:app'
    'copy:fonts'
    'copy:images'
    'copy:vendor'
    'bower:client'
    # TODO: Fix the coffee2css task, it doesn't currently work
    #'coffee2css'
    'jade:client'
    'less:client'
    'i18next-yaml'
  ]

  grunt.registerTask 'dist', [
    'build'
    'requirejs:dist'
  ]

  grunt.registerTask 'publish', [
    'clean:static'
    'copy:publish'
  ]

  grunt.registerTask 'start', [
    'build'
    'publish'
    'coffee:server'
    'express:dev'
    'watch'
  ]
