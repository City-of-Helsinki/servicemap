module.exports = (grunt, options) ->
  return {
    options:
      paths: ['styles']
    dev:
      files:
        '<%= build %>/css/servicemap.css': 'styles/servicemap.less'
        '<%= build %>/css/servicemap_ie.css': 'styles/servicemap_ie.less'
        '<%= build %>/css/servicemap_ie9.css': 'styles/servicemap_ie9.less'
    dist:
      options:
        compress: true
        cleancss: true
        optimization: 2
      files:
        '<%= build %>/css/servicemap.css': 'styles/servicemap.less'
        '<%= build %>/css/servicemap_ie.css': 'styles/servicemap_ie.less'
        '<%= build %>/css/servicemap_ie9.css': 'styles/servicemap_ie9.less'
  }
