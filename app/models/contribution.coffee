# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "ContributionModel", ["communityCirclesUtil", "restangular"]

module.factory "ContributionRestangular", (Config, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}/contrib"
    RestangularConfigurer.setRequestSuffix "/"
    # RestangularConfigurer.setRestangularFields
    #  id: "id"