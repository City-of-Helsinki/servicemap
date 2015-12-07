module.exports = (grunt, options) ->
  return {
    options:
      client: true
      files:
        '<%= build %>/js/templates.js': ['views/templates/**/*.jade']
    dev:
      options:
        data:
          debug: true
    dist:
      options:
        data:
          debug: false
  }
