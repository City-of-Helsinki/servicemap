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
      tasks: ['copy:app', 'coffee:server', 'express:dev']
    client:
      files: [
        '<%= src %>/*.coffee'
        '<%= src %>/views/*.coffee'
      ]
      tasks: ['copy:app', 'publish']
    coffee2css:
      files: [
        'grunt/tasks/color2css.coffee'
        '<%= src %>/color.coffee'
      ]
      tasks: ['coffee2css', 'publish']
    less:
      files: ['<%= styles %>/**/*.less']
      tasks: ['less', 'publish']
    i18n:
      files: ['<%= locales %>/*.yaml']
      tasks: ['i18next-yaml', 'publish']
    jade:
      files: ['<%= views %>/**/*.jade']
      tasks: ['jade', 'publish']
    livereload:
      options:
        livereload: true
      files: [
        '<%= watch.express.files %>'
        '<%= watch.client.files %>'
        '<%= watch.coffee2css.files %>'
        #'<%= watch.less.files %>'
        'static/css/*.css'
        '<%= watch.i18n.files %>'
        '<%= watch.jade.files %>'
      ]
  }
