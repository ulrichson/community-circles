imprintApp = angular.module("imprintApp", ["ngTouch"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/imprint/index.html
#------------------------------------------------------------------------------- 
imprintApp.controller "IndexCtrl", ($scope) ->
  $scope.close = ->
    steroids.modal.hide()