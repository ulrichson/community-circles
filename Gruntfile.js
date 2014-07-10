/*
 * Default Gruntfile for AppGyver Steroids
 * http://www.appgyver.com
 *
 * Licensed under the MIT license.
 */

'use strict';

module.exports = function(grunt) {

  grunt.initConfig({
    nggettext_extract: {
      pot: {
        files: {
          "po/template.pot": ["dist/views/**/*.html", "dist/controllers/*.js"]
        }
      },
    },
    nggettext_compile: {
      all: {
        files: {
          "dist/javascripts/translations.js": ["po/*.po"]
        }
      },
    },
    ngtemplates: {
      app: {
        cwd: "app/templates",
        src: "**.html",
        dest: "dist/javascripts/templates.js",
        options: {
          module: "templates",
          standalone: true
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-steroids");
  grunt.loadNpmTasks("grunt-angular-gettext");
  grunt.loadNpmTasks('grunt-angular-templates');

  grunt.registerTask("default", ["steroids-make", "steroids-compile-sass", "nggettext_extract", "nggettext_compile", "ngtemplates"]);

};
