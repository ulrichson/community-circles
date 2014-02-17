# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "CommunityModel", ["communityCirclesApp", "restangular"]

module.factory "CommunityRestangular", (Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "http://localhost/data/demo"
    RestangularConfigurer.setRequestSuffix ".json"