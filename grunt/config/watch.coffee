module.exports = (grunt) ->
  return {
    options:
      interval: 1000
    express:
      files: [
        'Gruntfile.coffee'
        'server-src/*.coffee'
        'config/*.yml'
      ]
      options:
        spawn: false
      tasks: ['copy:app', 'coffee:server', 'express:dev']
    client:
      files: [
        '<%= src %>/*.coffee'
        '<%= src %>/views/*.coffee'
        '<%= src %>/util/*.coffee'
      ]
      tasks: ['copy:app']
    coffee2css:
      files: [
        'grunt/tasks/color2css.coffee'
        '<%= src %>/color.coffee'
      ]
      tasks: ['coffee2css']
    less:
      files: ['<%= styles %>/**/*.less']
      tasks: ['less']
    i18n:
      files: ['<%= locales %>/*.yaml']
      tasks: ['i18next-yaml']
    jade:
      files: ['<%= views %>/**/*.jade']
      tasks: ['jade', 'sync:publish']
    livereload_refresh_browser:
      options:
        livereload: true
      tasks: ['publish']
      files: [
        '<%= build %>/**/*'
        '!<%= build %>/css/*.css'
      ]
    livereload_css:
      options:
        livereload: true
      tasks: ['publish']
      files: [
        '<%= build %>/css/*.css'
      ]
  }
