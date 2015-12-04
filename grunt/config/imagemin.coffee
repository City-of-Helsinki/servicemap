module.exports = (grunt, options) ->
  return {
    dist:
      files: [
        expand: true
        cwd: '<%= assets %>/images'
        src: ['**/*.{png,jpg,gif}']
        dest: '<%= build %>/images'
      ]
  }
