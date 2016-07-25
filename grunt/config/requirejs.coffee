module.exports = (grunt, options) ->
  return {
    options:
      baseUrl: '<%= build %>/js'
      exclude: ['coffee-script']
      stubModules: ['cs/cs']
      mainConfigFile: '<%= build %>/js/app/config.js'
      optimize: 'uglify2'
      optimizeAllPluginResources: true
      wrapShim: true
      generateSourceMaps: true
      preserveLicenseComments: false
      findNestedDependencies: true
      useSourceUrl: false
    app:
      options:
        include: ['app/config', 'app/main']
        out: '<%= build %>/js/bundle.js'
    embed:
      options:
        include: ['app/main-embed']
        out: '<%= build %>/js/embed.js'
  }
