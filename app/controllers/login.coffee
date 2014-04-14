loginApp = angular.module "loginApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch",
  "ngAnimate"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope, Util, Log) ->
  $scope.loginVisible = true
  $scope.buttonText = "Register"

  $scope.login = ->
    Util.login()
    Util.return()

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
