
requirejs = require 'requirejs'
requirejs.config
    baseUrl: __dirname    
    paths:
        app: '../static/js'
    nodeRequire: require

color = requirejs 'app/color'

css_template = """
           .service-<%= hover %><%= background %>color-<%= key %><%= hover_pc %> {
             <%= background %>color: <%= color %>;
           }
           """

module.exports = (grunt) ->
    grunt.registerMultiTask "coffee2css", "Generate css classes from colors in a coffeescript file.", ->
        grunt.log.writeln "Generating CSS for service colors."
        options = @options()
        css_output = ''
        for background in [true, false]
            for hover in [true, false]
                css_output += "\n" + (grunt.template.process(
                    css_template,
                    data:
                        key: key
                        color: value
                        background: if background then "background-" else ""
                        hover: if hover then "hover-" else ""
                        hover_pc: if hover then ":hover" else "") for own key, value of color.colors).join "\n"

        grunt.file.write options.output, css_output + "\n"
        return
    return
