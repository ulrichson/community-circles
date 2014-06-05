# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "NotificationModel", ["communityCirclesUtil", "restangular"]

module.factory "NotificationRestangular", (Config, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}"
    RestangularConfigurer.setRequestSuffix "/"
    # RestangularConfigurer.setRestangularFields
    #  id: "id"