module.exports = (grunt, options) ->
  return {
    fi:
      src: 'locales/*.yaml'
      dest: '<%= build %>/locales/fi.json'
      options:
        language: 'fi'
    sv:
      src: 'locales/*.yaml'
      dest: '<%= build %>/locales/sv.json'
      options:
        language: 'sv'
    en:
      src: 'locales/*.yaml'
      dest: '<%= build %>/locales/en.json'
      options:
        language: 'en'
  }
