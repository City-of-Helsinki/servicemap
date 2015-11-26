module.exports = (grunt, options) ->
  return {
    client:
      options:
        paths: ['styles']
      files:
        '<%= build %>/css/servicemap.css': 'styles/servicemap.less'
        '<%= build %>/css/bootstrap.css': 'styles/bootstrap/bootstrap.less'
        '<%= build %>/css/servicemap_ie.css': 'styles/servicemap_ie.less'
        '<%= build %>/css/servicemap_ie9.css': 'styles/servicemap_ie9.less'
  }
