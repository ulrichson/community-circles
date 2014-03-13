notificationApp = angular.module("notificationApp", ["ngTouch"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/notification/index.html
#------------------------------------------------------------------------------- 
notificationApp.controller "IndexCtrl", ($scope) ->
  $scope.close = ->
    steroids.modal.hide()