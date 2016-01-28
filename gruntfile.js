module.exports = function(grunt) {
  grunt.loadNpmTasks("grunt-contrib-connect");
  grunt.loadNpmTasks("grunt-air-sdk");

  grunt.initConfig({
    air_sdk: {
      vpaidjs_swf: {
        options: {
          bin: "mxmlc",
          rawConfig: "-source-path ./src -debug=false -warnings=false -strict=true -optimize=true -incremental=false -define+=CONFIG::debugging,false -define+=CONFIG::ga,false -define+=CONFIG::connectors,false -define+=CONFIG::callbacks,true -define+=CONFIG::buttons,false -define+=CONFIG::javascript,true -define+=CONFIG::release,true"
        },
        files: {
         "dist/vpaidjs.swf": "src/VPAIDJS.as"
        }
      }
    },
    connect: {
      server: {
        options: {
          debug: true,
          keepalive: true,
          port: grunt.option("port") || 8000
        }
      }
    },
  });

  grunt.registerTask("build", [
    "air_sdk:vpaidjs_swf"
  ]);
};
