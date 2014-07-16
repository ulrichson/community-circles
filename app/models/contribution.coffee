# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "ContributionModel", ["common", "restangular"]

module.factory "ContributionRestangular", (Config, Session, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}/contrib"
    RestangularConfigurer.setRequestSuffix "/"
    RestangularConfigurer.setDefaultHeaders "Authorization": "Token #{Session.token()}"