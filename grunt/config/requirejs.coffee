module.exports = (grunt, options) ->
  return {
    options:
      baseUrl: '<%= build %>/js'
      include: ['app/main']
      exclude: ['coffee-script']
      out: '<%= build %>/js/bundle.js'
      stubModules: ['cs']
      mainConfigFile: '<%= build %>/js/app/config.js'
      generateSourceMaps: true
      preserveLicenseComments: false
      findNestedDependencies: true
      useSourceUrl: true
    dist:
      options:
        optimize: 'uglify2'
  }
