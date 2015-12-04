module.exports = (grunt) ->
  return {
    express:
      files: [
        'Gruntfile.coffee'
        'server-src/*.coffee'
        'config/*.yml'
      ]
      options:
        spawn: false
      tasks: ['newer:copy:app', 'coffee:server', 'express:dev']
    client:
      files: ['<%= src %>/*.coffee', '<%= src %>/views/*.coffee']
      tasks: ['copy:app']
#    coffee2css:
#      files: ['Gruntfile.coffee', '<%= src %>/color.coffee']
#      tasks: 'coffee2css'
    less:
      files: ['<%= styles %>/**/*.less']
      tasks: ['less']
    i18n:
      files: ['<%= locales %>/*.yaml']
      tasks: ['i18next-yaml']
    jade:
      files: ['<%= views %>/**/*.jade']
      tasks: ['jade']
    livereload:
      options:
        livereload: true
      files: [
        'config/*.yml'
        '<%= build %>/js/*.{coffee,js}'
        '<%= build %>/css/*.css'
      ]
  }
