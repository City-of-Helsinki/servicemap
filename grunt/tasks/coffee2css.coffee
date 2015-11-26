module.exports = (grunt) ->
  path = require 'path'
  requirejs = require 'requirejs'
  requirejs.config
    baseUrl: path.join __dirname, '../../.build'
    paths:
      app: 'app'
    nodeRequire: require

  cssTemplate = """
              .service-<%= hover %><%= background %>color-<%= light %><%= key %><%= hoverPc %> {
                  <%= background %>color: <%= color %> !important;
              }
              """

  grunt.registerMultiTask 'coffee2css', 'Generate css classes from colors in a coffeescript file.', ->
    ColorMatcher = requirejs 'cs!app/color'
    grunt.log.writeln "Generating CSS for service colors."
    options = @options()
    cssOutput = ''
    for background in [true, false]
      for pseudo in ['hover', 'focus', '']
        for light in [true, false]
          cssOutput += "\n" + (grunt.template.process(
              cssTemplate,
              data:
                key: key
                color: if light then ColorMatcher.rgba(r, g, b, "0.30") else ColorMatcher.rgb(r, g, b)
                background: if background then "background-" else ""
                light: if light then "light-" else ""
                hover: if pseudo == '' then "" else "hover-"
                hoverPc: if pseudo != '' then ":" + pseudo) for own key, [r, g, b] of ColorMatcher.serviceColors).join "\n"

    grunt.file.write options.output, cssOutput + "\n"
