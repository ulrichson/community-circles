poiApp = angular.module "poiApp", ["communityCirclesUtil", "PoiModel", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, Util, PoiRestangular) ->

  $scope.message_id = "poiIndexCtrl"
  $scope.loading = false

  latLngOnLocate = null
  currentPositionMarker = null

  map = new L.Map "map",
    zoom: 10
    zoomControl: false

  visibilityChanged = ->
    # POIs are prefetched, however, reload if you moved too far
    # if document.visibilityState is "visible" and latLngOnLocate isnt null and Util.lastKnownPosition.distanceTo(latLngOnLocate) < 50
    #   locate()

  selectPoi = (poi) ->
    $scope.selectedPoi = poi
    Util.send "contributionNewCtrl", "setPoi", poi

  locate = ->
    map.locate setView: true
    $scope.loading = true
   
  $scope.choose = (poi) ->
    map.panTo new L.LatLng poi.location.lat, poi.location.lng
    selectPoi poi.name

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
      venuesLayer = new L.LayerGroup
      _.each result.response.venues, (venue) ->
        latlng = new L.LatLng venue.location.lat, venue.location.lng
        poiMarker = new L.Marker latlng
        poiMarker.data = venue
        poiMarker.on "click", (e) ->
          map.panTo e.latlng
          selectPoi e.target.data.name

          # Scroll to selected element
          $location.hash e.target.data.id
          $anchorScroll()

          $scope.$apply()
        venuesLayer.addLayer poiMarker 
      map.addLayer venuesLayer
      # map.fitBounds venuesLayer.getBounds()

      # Add current position marker
      map.removeLayer currentPositionMarker unless currentPositionMarker is null
      currentPositionMarker = Util.createPositionMarker e.latlng
      map.addLayer currentPositionMarker, true

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
