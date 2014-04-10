loginApp = angular.module "loginApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope, Util, Log) ->
  $scope.login = ->
    Util.login()
    Util.return()

  $scope.register = ->
    alert "not done yet"

  steroids.view.setBackgroundColor "#00a8b3"
