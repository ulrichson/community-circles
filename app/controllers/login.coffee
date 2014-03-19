loginApp = angular.module "loginApp", ["ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope) ->
  $scope.login = ->
    window.localStorage.setItem "loggedIn", true
    steroids.modal.hide()

  $scope.register = ->
    alert "not done yet"