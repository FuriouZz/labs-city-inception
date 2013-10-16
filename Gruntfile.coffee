module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    connect:
      dist:
        options:
          port: 4000
          base: "www/dist"

      dev:
        options:
          port: 4000
          base: "www/app"

    notify:
      watch:
        options:
          message: "Sass or Js reloaded"

      connect:
        options:
          message: "Server is ready!"

    watch:
      sass:
        files: ["src/sass/*.sass", "src/coffee/*.coffee"]
        tasks: ["compass:dev", "coffee:compile", "notify:watch"]
        options:
          livereload: true

      other:
        files: "www/app/scripts/!vendor/**/*.*"
        options:
          livereload: true

    # sass:
    #   dist:
    #     options:
    #       style: "compressed"

    #     files:
    #       "./www/dist/css/app.css": "./src/sass/app.sass"

    #   dev:
    #     options:
    #       style: "expanded"

    #     files:
    #       "./www/app/css/app.css": "./src/sass/app.sass"

    compass:
      dist:
        options:
          config: 'config/config.rb'
          outputStyle: "compress"
          sassDir: "src/sass"

      dev:
        options:
          config: 'config/config.rb'
          outputStyle: "expanded"
          sassDir: 'src/sass'

    coffee:
      compile:
          files:
            './www/app/scripts/app.js': './src/coffee/app.coffee'


  # Load NPM Tasks
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-compass"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-notify"
  grunt.registerTask "run", ["compass:dev", "connect:dev", "notify", "watch"]
  grunt.registerTask "prod", ["sass:dist", "connect:dist"]

  # Default Task
  grunt.registerTask "default", ["run"]
