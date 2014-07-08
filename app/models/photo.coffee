# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "PhotoModel", ["common", "restangular"]

module.factory "PhotoRestangular", (Config, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}"
    RestangularConfigurer.setRequestSuffix "/"
    # RestangularConfigurer.setRestangularFields
    #  id: "id"