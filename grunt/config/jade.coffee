module.exports = (grunt, options) ->
  return {
    client:
      options:
        client: true
      files:
        '<%= build %>/js/templates.js': ['views/templates/**/*.jade']
  }
