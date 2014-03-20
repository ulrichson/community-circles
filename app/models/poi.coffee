# The contents of individual model .js files will be concatenated into dist/models.js

# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "PoiModel", ["restangular"]

module.factory "PoiRestangular", (Restangular) ->
  
  return Restangular.withConfig (RestangularConfigurer) ->

    RestangularConfigurer.setBaseUrl "https://api.foursquare.com/v2"
    RestangularConfigurer.setDefaultRequestParams
      client_id: @key.FOURSQUARE_CLIENT_ID
      client_secret: @key.FOURSQAURE_CLIENT_SECTRET
      v: "20140420"