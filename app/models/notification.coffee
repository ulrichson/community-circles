# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "NotificationModel", ["common", "restangular"]

module.factory "NotificationRestangular", (Config, Session, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}"
    RestangularConfigurer.setRequestSuffix "/"
    RestangularConfigurer.setDefaultHeaders "Authorization": "Token #{Session.token()}"