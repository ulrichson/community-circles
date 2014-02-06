imprintApp = angular.module("imprintApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/imprint/index.html
#------------------------------------------------------------------------------- 
imprintApp.controller "IndexCtrl", ($scope) ->
  $scope.close = ->
    steroids.modal.hide()