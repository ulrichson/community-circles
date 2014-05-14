profileApp = angular.module "profileApp", [
  "communityCirclesApp",
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/profile/index.html
#------------------------------------------------------------------------------- 
profileApp.controller "IndexCtrl", ($scope, app, Util, Log, Config) ->
  $scope.loggedIn = app.loggedIn()
  $scope.supportEmail = Config.SUPPORT_EMAIL

  $scope.logout = ->
    Util.logout()

  $scope.settings = ->
    steroids.modal.show new steroids.views.WebView "/views/settings/index.html"

  $scope.imprint = ->
    steroids.modal.show new steroids.views.WebView "/views/imprint/index.html"

  Util.autoRestoreView()