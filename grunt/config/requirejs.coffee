module.exports = (grunt, options) ->
  return {
    options:
      baseUrl: '<%= build %>/js'
      include: ['app/main']
      out: '<%= build %>/js/bundle.js'
      stubModules: ['cs']
      mainConfigFile: '<%= build %>/js/app/config.js'
      generateSourceMaps: true
      preserveLicenseComments: false
      findNestedDependencies: true
    dist:
      options:
        optimize: 'uglify2'
  }
