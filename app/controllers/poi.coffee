poiApp = angular.module "poiApp", ["communityCirclesUtil", "PoiModel", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope, Util, PoiRestangular) ->
  $scope.message_id = "poiIndexCtrl"
  load = ->
    $scope.loading = true
    navigator.geolocation.getCurrentPosition (position) ->
      PoiRestangular.all("venues/search").getList(ll: "#{position.coords.latitude},#{position.coords.longitude}").then (result) ->
        $scope.pois = result.response.venues
        $scope.$apply -> $scope.loading = false
      , (error) ->
        alert "Sorry, could not load locations."
        console.error "Failed API call: #{error}"
        $scope.$apply -> $scope.loading = false
    , (error) ->
      alert "Sorry, cannot determine position."
      console.error "Failed to get current position: {error}"
      $scope.$apply -> $scope.loading = false
    , enableHighAccuracy: true
    
  $scope.choose = (poi) ->
    $scope.selectedPoi = poi
    Util.send "contributionNewCtrl", "setPoi", poi
    Util.return()

  $scope.reset = ->
    $scope.selectedPoi = null
    load()

  Util.consume $scope
  load()
