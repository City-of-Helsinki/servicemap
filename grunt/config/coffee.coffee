module.exports = (grunt, options) ->
  return {
    server:
      expand: true
      cwd: 'server-src'
      src: ['*.coffee']
      dest: 'server-js/'
      ext: '.js'
    test:
      expand: true
      cwd: 'test/src'
      src: ['*.coffee']
      dest: '<%= build %>/test/'
      ext: '.js'
  }
