module.exports = (grunt) ->
  return {
    colors:
      options:
        output: '<%= build %>/css/colors.css'
      files:
        '<%= build %>/css/colors.css': ['<%= build %>/js/app/color.coffee']
  }
