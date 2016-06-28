module.exports = (grunt, options) ->
  publish:
    files: [
      #expand: true
      cwd: '<%= build %>'
      src: [
        'css/*.css'
        'fonts/**/*.{css,eot,svg,tff,woff,woff2}'
        'js/**/*.{js,js.map,coffee}'
        'vendor/**/*.{css,min.css,js}'
        'locales/*.json'
        'images/**/*.png'
        'icons/**'
        'test/*.js'
      ]
      dest: '<%= static %>'
    ]
