_ = require 'underscore'

module.exports = (grunt) ->
  deps = ['underscore', 'baconjs', 'bacon.jquery']
  shim =
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

      deps:
        src: []
        dest: 'dist/deps.js'
        options:
          alias: deps
          shim: _.pick(shim, ['promise', 'jquery'])

      rdIndex:
        src: ['src/rdIndex.coffee']
        dest: 'dist/rdIndex.js'
        options:
          transform: ['coffeeify']
          shim: shim
          external: deps.concat _.pluck(shim, 'path')

      lib:
        src: ['src/lib.coffee']
        dest: 'dist/remotedisplaylib.js'
        options:
          transform: ['coffeeify']

      defaultRemoteDisplay:
        src: ['src/defaultRemoteDisplay.coffee']
        dest: 'dist/defaultRemoteDisplay.js'
        options:
          transform: ['coffeeify']

      coffeeChat:
        src: ['src/coffeeChat.coffee']
        dest: 'dist/coffeeChat.js'
        options:
          transform: ['coffeeify']

    clean:
      dist: ['dist']

    uglify:
      dist:
        files:
          'dist/deps.js': 'dist/deps.js'
          'dist/rdIndex.js':  'dist/rdIndex.js'

    watch:
      all:
        files: ['src/**/*.coffee', 'src/**/*.js']
        tasks: ['browserify:rdIndex', 'browserify:lib', 'browserify:defaultRemoteDisplay', 'browserify:coffeeChat']

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'dist', ['clean:dist', 'browserify:deps', 'browserify:rdIndex', 'browserify:lib', 'browserify:defaultRemoteDisplay', 'browserify:coffeeChat']
  grunt.registerTask 'default', ['dist']
