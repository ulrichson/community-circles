# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "bPart", ["common", "restangular"]

module.factory "Backend", (Config, Session, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}"
    RestangularConfigurer.setDefaultHeaders "Authorization": "Token #{Session.token()}"