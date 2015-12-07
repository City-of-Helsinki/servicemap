module.exports = (grunt, options) ->
  return {
    options:
      client: true
    dev:
      files:
        '<%= build %>/js/templates.js': ['views/templates/**/*.jade']
      options:
        data:
          debug: true
    dist:
      files:
        '<%= build %>/js/templates.js': ['views/templates/**/*.jade']
      options:
        data:
          debug: false
  }
