_ = require 'underscore'

module.exports = (grunt) ->
  deps = ['underscore', 'baconjs', 'bacon.jquery']
  shim =
    webinos:
      path: 'vendor/webinos.js'
      exports: 'webinos'
    promise:
      path: 'vendor/promise.js'
      exports: 'Promise'
    jquery:
      path: 'vendor/jquery.js'
      exports: '$'

  grunt.initConfig
    browserify:
      options:
        debug: no # yes

      wrt:
        src: []
        dest: 'dist/wrt.js'
        options:
          shim: _.pick(shim, 'webinos')
          ignore: ['crypto', 'path', './logging.js', './registry.js', 'webinos-utilities']

      deps:
        src: []
        dest: 'dist/deps.js'
        options:
          alias: deps
          shim: _.pick(shim, ['promise', 'jquery'])

      app:
        src: ['src/app.coffee']
        dest: 'dist/app.js'
        options:
          transform: ['coffeeify']
          shim: shim
          external: deps.concat _.pluck(shim, 'path')

      screen:
        src: ['src/screen.coffee']
        dest: 'dist/screen.js'
        options:
          transform: ['coffeeify']
          shim: shim
          external: deps.concat _.pluck(shim, 'path')

    clean:
      dist: ['dist']

    uglify:
      dist:
        files:
          'dist/wrt.js':  'dist/wrt.js'
          'dist/deps.js': 'dist/deps.js'
          'dist/app.js':  'dist/app.js'
          'dist/screen.js':  'dist/screen.js'

    watch:
      all:
        files: ['src/**/*.coffee', 'src/**/*.js']
        tasks: ['browserify:app', 'browserify:screen']

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'dist', ['clean:dist', 'browserify:wrt', 'browserify:deps', 'browserify:app', 'browserify:screen']
  grunt.registerTask 'default', ['dist']
