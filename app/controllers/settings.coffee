settingsApp = angular.module "settingsApp", ["communityCirclesUtil", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/settings/index.html
#------------------------------------------------------------------------------- 
settingsApp.controller "IndexCtrl", ($scope, Util) ->
  $scope.close = ->
    steroids.modal.hide()