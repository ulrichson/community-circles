poiApp = angular.module("poiApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope) ->
  $scope.pois = [
    title: "Place 1"
  ,
    title: "Place 2"
  ,
    title: "Place 3"
  ]
  
  $scope.selectedPoi = steroids.view.params.poi
  
  $scope.choose = (poi) ->
    window.postMessage
      recipient: "contributionView"
      poi: poi
    steroids.layers.pop()
