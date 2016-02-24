module.exports = (grunt, options) ->
  return {
    fonts:
      files: [
        expand: true
        cwd: '<%= assets %>/fonts'
        src: ['**/*.{css,eot,svg,tff,woff,woff2}']
        dest: '<%= build %>/fonts'
      ]
    images:
      files: [
        expand: true
        cwd: '<%= assets %>/images'
        src: ['**/*.png']
        dest: '<%= build %>/images'
      ]
    icons:
      files: [
        expand: true
        cwd: '<%= assets %>/icons'
        src: ['**']
        dest: '<%= build %>/icons'
        ]
    publish: # NOT IN USE - see sync
      files: [
        expand: true
        cwd: '<%= build %>'
        src: [
          'css/*.css'
          'fonts/**/*.{css,eot,svg,tff,woff,woff2}'
          'js/**/*.{js,js.map,coffee}'
          'vendor/**/*.{css,min.css,js}'
          'locales/*.json'
          'images/**/*.png'
        ]
        dest: '<%= static %>'
      ]
    vendor:
      files: [
        expand: true
        cwd: '<%= assets %>/vendor'
        src: ['**/*.js', '**/*.css']
        dest: '<%= build %>/vendor'
      ]
    app:
      files: [
        expand: true
        cwd: '<%= src %>'
        src: ['**/*.coffee', '**/*.js']
        dest: '<%= build %>/js/app'
      ]
  }
