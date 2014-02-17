# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "ContributionModel", ["communityCirclesApp", "restangular"]

module.factory "ContributionRestangular", (Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "http://localhost/data/demo"
    RestangularConfigurer.setRequestSuffix ".json"
    # RestangularConfigurer.setRestangularFields
    #  id: "id"