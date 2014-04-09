notificationApp = angular.module "notificationApp", ["communityCirclesUtil", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/notification/index.html
#------------------------------------------------------------------------------- 
notificationApp.controller "IndexCtrl", ($scope, Util) ->
  $scope.close = ->
    steroids.modal.hide()