module.exports = (grunt, options) ->
  return {
    server:
      expand: true
      cwd: 'server-src'
      src: ['*.coffee']
      dest: 'server-js/'
      ext: '.js'
  }
