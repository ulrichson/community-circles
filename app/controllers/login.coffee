loginApp = angular.module "loginApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "AccountModel",
  "ngTouch",
  "ngAnimate"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope, $http, Util, Log, Config, UI, AccountRestangular) ->
  $scope.loginVisible = true
  $scope.buttonText = "Register"

  $scope.login = {}

  $scope.login = ->
    if not $scope.login.username? or not $scope.login.password?
      UI.alert
        message: "Please enter your crededentials!"
      return

    credentials = btoa "#{$scope.login.username}:#{$scope.login.password}"

    # AccountRestangular.all("users").getList {},
    #   "Authorization": "Basic #{credentials}"
    # .then (response) ->
    #   UI.alert message: "yess"
    # , (error) ->
    #   Log.d JSON.stringify error
    #   UI.alert message: error.data.detail

    $scope.requesting = true

    $http
      url: "#{Config.API_ENDPOINT}/accounts/users/"
      method: "GET"
      headers:
        "Authorization": "Basic #{credentials}"
    .success (data) ->
      Util.login data.results[0].username, data.results[0].id      
      steroids.layers.popAll()

      $scope.login.username = null
      $scope.login.password = null
      $scope.requesting = false
    .error (data) ->
      UI.alert message: data.detail
      $scope.requesting = false

  $scope.register = ->
    alert "not done yet"

  $scope.switchView = ->
    if $scope.loginVisible
      $scope.loginVisible = false
      $scope.buttonText = "Back to login"
    else
      $scope.loginVisible = true
      $scope.buttonText = "Register"

  steroids.view.setBackgroundColor "#00a8b3"
