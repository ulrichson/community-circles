loginApp = angular.module("loginApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope) ->
  $scope.login = ->
    steroids.modal.hide()

  $scope.register = ->
    alert "not done yet"