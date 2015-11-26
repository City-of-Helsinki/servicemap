module.exports = (grunt, options) ->
  return {
    options:
      override: require '../helpers/check-for-imports.coffee'
  }
