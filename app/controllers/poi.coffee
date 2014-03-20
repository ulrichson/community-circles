poiApp = angular.module "poiApp", ["PoiModel", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope, PoiRestangular) ->
  navigator.geolocation.getCurrentPosition (position) ->
    PoiRestangular.all("venues/search").getList(ll: "#{position.coords.latitude},#{position.coords.longitude}").then (result) ->
      $scope.pois = result.response.venues
    , (error) ->
      alert "Sorry, could not load locations."
      console.error "Failed API call: #{error}"
  , (error) ->
    alert "Sorry, cannot determine position."
    console.error "Failed to get current position: {error}"
  , enableHighAccuracy: true
  
  $scope.selectedPoi = steroids.view.params.poi
  
  $scope.choose = (poi) ->
    window.postMessage
      recipient: "contributionView"
      poi: poi
    steroids.layers.pop()
