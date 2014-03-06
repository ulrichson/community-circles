settingsApp = angular.module("settingsApp", ["hmTouchEvents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/settings/index.html
#------------------------------------------------------------------------------- 
settingsApp.controller "IndexCtrl", ($scope) ->
  $scope.close = ->
    steroids.modal.hide()