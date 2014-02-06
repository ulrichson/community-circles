notificationApp = angular.module("notificationApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/notification/index.html
#------------------------------------------------------------------------------- 
notificationApp.controller "IndexCtrl", ($scope) ->
  $scope.close = ->
    steroids.modal.hide()