profileApp = angular.module("profileApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/profile/index.html
#------------------------------------------------------------------------------- 
profileApp.controller "IndexCtrl", ($scope) ->
  $scope.logout = ->
    window.logout()

  $scope.settings = ->
    steroids.modal.show new steroids.views.WebView "/views/settings/index.html"

  $scope.imprint = ->
    steroids.modal.show new steroids.views.WebView "/views/imprint/index.html"