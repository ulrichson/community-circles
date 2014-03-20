poiApp = angular.module "poiApp", ["communityCirclesUtil", "PoiModel", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope, Util, PoiRestangular) ->

  $scope.message_id = "poiIndexCtrl"
  $scope.loading = false

  latLngOnLocate = null;

  map = new L.Map "map",
    zoom: 10
    zoomControl: false

  visibilityChanged = ->
    # POIs are prefetched, however, reload if you moved too far
    # if document.visibilityState is "visible" and latLngOnLocate isnt null and Util.lastKnownPosition.distanceTo(latLngOnLocate) < 50
    #   locate()

  locate = ->
    map.locate setView: true
    $scope.loading = true
   
  $scope.choose = (poi) ->
    $scope.selectedPoi = poi
    Util.send "contributionNewCtrl", "setPoi", poi
    Util.return()

  $scope.reset = ->
    $scope.selectedPoi = null
    locate()

  Util.consume $scope

  Util.createTileLayer().addTo map
  locate()

  map.on "locationfound", (e) ->
    latLngOnLocate = e.latlng
    PoiRestangular.all("venues/search").getList(ll: "#{e.latlng.lat},#{e.latlng.lng}").then (result) ->
      $scope.pois = result.response.venues
      # alert result.response.venues.length
      venuesLayer = new L.LayerGroup
      _.each result.response.venues, (venue) ->
        latlng = new L.LatLng venue.location.lat, venue.location.lng
        poiMarker = new L.Marker latlng
        venuesLayer.addLayer poiMarker 
      map.addLayer venuesLayer
      # map.fitBounds venuesLayer.bounds
      $scope.loading = false
    , (error) ->
      alert "Sorry, could not load locations. #{JSON.stringify error}"
      console.error "Failed API call: #{error}"
      $scope.loading = false

  map.on "locationerror", (e) ->
    alert "Sorry, cannot determine position."
    console.error "Failed to get current position: {e}"
    $scope.loading = false

  document.addEventListener "visibilitychange", visibilityChanged, false
