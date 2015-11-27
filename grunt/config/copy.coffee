module.exports = (grunt, options) ->
  return {
    almond:
      files: [
        expand: true
        cwd: 'bower_components/almond'
        src: ['almond.js']
        dest: '<%= build %>/js/'
      ]
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
    publish:
      files: [
        expand: true
        cwd: '<%= build %>'
        src: [
          'css/*.css'
          'fonts/**/*.{css,eot,svg,tff,woff,woff2}'
          'js/*.{js,js.map}'
          'js/app/**/*.coffee'
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
    main:
      files: [
        expand: true
        cwd: '<%= src %>'
        src: ['main.js']
        dest: '<%= build %>/js'
      ]
    app:
      files: [
        expand: true
        cwd: '<%= src %>'
        src: ['**/*.coffee', 'main.js']
        dest: '<%= build %>/js/app'
      ]
  }
