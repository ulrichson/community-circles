# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "bPart", ["common", "restangular"]

module.factory "Backend", (Config, Session, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl "#{Config.API_ENDPOINT}"
    RestangularConfigurer.setDefaultHeaders "Authorization": "Token #{Session.token()}"
    # RestangularConfigurer.setErrorInterceptor (response, deferred, responseHandler) ->
    #   if response.status is 401
    #     localStorage.setItem "loggedIn", "false"
    #     localStorage.removeItem "login.username"
    #     localStorage.removeItem "login.token"
    #     return true
    #   else
    #     return false