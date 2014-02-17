# The contents of individual model .js files will be concatenated into dist/models.js

# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "MoodModel", ["restangular"]

module.factory "MoodRestangular", (Restangular) ->
  
  return Restangular.withConfig (RestangularConfigurer) ->

    RestangularConfigurer.setBaseUrl "http://localhost/data"
    RestangularConfigurer.setRequestSuffix ".json"
    # RestangularConfigurer.setRestangularFields
    #   id: "mood_id"