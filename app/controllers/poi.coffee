poiApp = angular.module "poiApp", [
  "mgcrea.pullToRefresh",
  "communityCirclesGame",
  "communityCirclesUtil",
  "communityCirclesLog",
  "PoiModel",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/poi/index.html
#------------------------------------------------------------------------------- 
poiApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, Util, Game, Log, PoiRestangular) ->

  $scope.message_id = "poiIndexCtrl"
  $scope.loading = false

  latLngOnLocate = null
  currentPositionMarker = null
  venuesLayer = null

  map = new L.Map "map",
    zoom: 10
    zoomControl: false

  visibilityChanged = ->
    # POIs are prefetched, however, reload if you moved too far
    if document.visibilityState is "visible" and latLngOnLocate isnt null and Util.lastKnownPosition().distanceTo(latLngOnLocate) < Game.initialRadius / 4
      $scope.reset()

  selectPoi = (poi) ->
    $scope.selectedPoi = poi.id
    Util.send "contributionNewCtrl", "setPoi", poi.name

  locate = ->
    map.locate setView: true
    $scope.loading = true
   
  $scope.choose = (poi) ->
    latlng = new L.LatLng poi.location.lat, poi.location.lng
    map.setView latlng, map.getMaxZoom() 
    selectPoi poi

  $scope.reset = ->
    $scope.selectedPoi = null
    locate()

  Util.consume $scope

  Util.createTileLayer().addTo map
  locate()

  map.on "locationfound", (e) ->
    latLngOnLocate = e.latlng
    PoiRestangular.all("venues/search").getList(ll: "#{e.latlng.lat},#{e.latlng.lng}", radius: Game.initialRadius, intent: "browse").then (result) ->
      $scope.pois = result.response.venues
      map.removeLayer venuesLayer unless venuesLayer is null
      venuesLayer = new L.FeatureGroup
      _.each result.response.venues, (venue) ->
        latlng = new L.LatLng venue.location.lat, venue.location.lng
        imgTag = ""
        if venue.categories[0]?
          imgSrc = "#{venue.categories[0].icon.prefix}44#{venue.categories[0].icon.suffix}"
          imgTag = "<img class=\"category-icon\" alt=\"#{venue.categories[0].name}\" src=\"#{imgSrc}\" width=\"22\">"
        poiMarker = new L.Marker latlng,
          icon: L.divIcon
            className: "poi-marker"
            iconAnchor: [12, 36]
            iconSize: [24, 36]
            html: "<div class=\"poi-icon\">#{imgTag}</div>"
        poiMarker.data = venue
        poiMarker.on "click", (e) ->
          latlng = new L.LatLng e.target.data.location.lat, e.target.data.location.lng
          map.setView latlng, map.getMaxZoom()

          selectPoi e.target.data

          # Scroll to selected element
          $location.hash e.target.data.id
          $anchorScroll()

          $scope.$apply()
        venuesLayer.addLayer poiMarker 
      map.addLayer venuesLayer
      map.fitBounds venuesLayer.getBounds(), padding: [30, 30]

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
