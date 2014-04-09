profileApp = angular.module "profileApp", [
  "communityCirclesApp",
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/profile/index.html
#------------------------------------------------------------------------------- 
profileApp.controller "IndexCtrl", ($scope, app, Util, Log) ->
  $scope.loggedIn = app.loggedIn()

  $scope.logout = ->
    app.logout()

  $scope.settings = ->
    steroids.modal.show new steroids.views.WebView "/views/settings/index.html"

  $scope.imprint = ->
    steroids.modal.show new steroids.views.WebView "/views/imprint/index.html"