module.exports = (grunt) ->

  path = require 'path'

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
  })

  grunt.loadTasks './grunt/tasks'

  grunt.registerTask 'build', [
    'clean:build'
    'copy:app'
    'copy:almond'
    'copy:main'
    'copy:fonts'
    'copy:images'
    'copy:vendor'
    'bower:client'
    'jade:client'
#    'coffee2css'
    'less:client'
    'i18next-yaml'
  ]

  grunt.registerTask 'dev', [
    'build'
  ]

  grunt.registerTask 'dist', [
    'build'
    'requirejs:dist'
  ]

  grunt.registerTask 'publish', [
    'clean:static'
    'copy:publish'
  ]

  grunt.registerTask 'build_server', [
    'dev'
    'publish'
    'coffee:server'
  ]

  grunt.registerTask 'start', [
    'build_server'
    'express:dev'
    'watch'
  ]
