# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "AccountModel", ["communityCirclesUtil", "restangular"]

module.factory "AccountRestangular", (Config, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}/accounts"
    RestangularConfigurer.setRequestSuffix "/"