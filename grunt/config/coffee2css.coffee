module.export = (grunt) ->
  return {
    color_mapping:
      options:
        output: '<%= assets %>/css/colors.css'
      files:
        '<%= build %>/css/colors.css': '<%= build %>/js/app/color.coffee'
  }
