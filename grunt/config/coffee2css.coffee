module.export = (grunt) ->
  return {
    color_mapping:
      options:
        output: '<%= build %>/css/colors.css'
      files:
        '<%= build %>/css/colors.css': ['<%= build %>/js/app/color.coffee']
  }
