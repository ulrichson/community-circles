poiApp = angular.module "poiApp", [
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

  iconSize = [28, 42]
  iconAnchor = [14, 42]
  iconLongerSide = if iconSize[0] > iconSize[1] then iconSize[0] else iconSize[1]
  paddingTopLeft = [iconSize[0] / 2 + 10, iconSize[1] + 10]
  paddingBottomRight = [iconSize[0] / 2 + 10, 10]

  $scope.loading = false

  latLngOnLocate = null
  currentPositionMarker = null

  selectedMarker = null
  selectedMarkerZIndex = 0
  maxZIndex = 0

  spiderfiedMarkers = null

  venuesLayer = null

  map = new L.Map "map",
    zoom: 10
    zoomControl: false

  oms = new OverlappingMarkerSpiderfier map,
    nearbyDistance: iconLongerSide

  visibilityChanged = ->
    # POIs are prefetched, however, reload if you moved too far
    if document.visibilityState is "visible" and latLngOnLocate isnt null and Util.lastKnownPosition().distanceTo(latLngOnLocate) > Game.initialRadius / 4
      Log.d "Distance since last visit: #{Util.lastKnownPosition().distanceTo(latLngOnLocate)}m"
      $scope.reset true

  unselectPois = ->
    selectedMarker._icon.style.zIndex = selectedMarkerZIndex unless selectedMarker is null
    _.each venuesLayer.getLayers(), (marker) -> marker._icon.className = marker._icon.className.replace " active", ""

    Util.send "contributionNewCtrl", "setPoi", null

    $scope.selectedPoi = null
    selectedMarker = null
    selectedMarkerZIndex = 0
    maxZIndex = 0

    map.fitBounds venuesLayer.getBounds(), paddingTopLeft: paddingTopLeft, paddingBottomRight: paddingBottomRight

  selectPoi = (poi) ->
    return if not venuesLayer? or not poi?
    
    $scope.selectedPoi = poi

    # Reset z-index of previously selected marker
    selectedMarker._icon.style.zIndex = selectedMarkerZIndex unless selectedMarker is null

    selectedMarker = null

    # Select marker in map
    _.each venuesLayer.getLayers(), (marker) ->
      # Reset style of all markers
      marker._icon.className = marker._icon.className.replace " active", ""

      selectedMarker = marker if marker.data.id is poi.id
      maxZIndex = marker._icon.style.zIndex if marker._icon.style.zIndex > maxZIndex

    if selectedMarker isnt null
      selectedMarkerZIndex = selectedMarker._icon.style.zIndex
      selectedMarker._icon.className += " active"
      selectedMarker._icon.style.zIndex = maxZIndex + 1

    latlng = new L.LatLng poi.location.lat, poi.location.lng
    map.setView latlng, map.getMaxZoom()
    # map.panTo latlng

    Util.send "contributionNewCtrl", "setPoi", poi.name

  locate = ->
    map.locate setView: false
    $scope.loading = true
   
  $scope.choose = (poi) ->
    if $scope.selectedPoi? and $scope.selectedPoi.id is poi.id
      unselectPois()
    else
      oms.unspiderfy()
      selectPoi poi

  $scope.reset = (keepSelected = false) ->
    if not keepSelected
      unselectPois()
      window.scrollTo 0, 0
    locate()

  map.dragging.disable()
  map.touchZoom.disable()
  map.doubleClickZoom.disable()
  map.scrollWheelZoom.disable()

  Util.consume $scope

  Util.createTileLayer().addTo map
  locate()

  map.on "locationfound", (e) ->
    latLngOnLocate = e.latlng
    PoiRestangular.all("venues/search").getList(ll: "#{e.latlng.lat},#{e.latlng.lng}", radius: Game.initialRadius, intent: "browse", limit: 10).then (result) ->
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
            iconAnchor: iconAnchor
            iconSize: iconSize
            html: "<div class=\"poi-icon\">#{imgTag}</div>"
        poiMarker.data = venue
        oms.addListener "click", (marker) ->
          if not _.contains spiderfiedMarkers, marker
            # if $scope.selectedPoi? and $scope.selectedPoi.id is marker.data.id
            #   unselectPois()
            # else
            selectPoi marker.data

            # Scroll to selected element
            $location.hash marker.data.id
            $anchorScroll()
            $scope.$apply()

        venuesLayer.addLayer poiMarker
        oms.addMarker poiMarker

      map.addLayer venuesLayer
      map.fitBounds venuesLayer.getBounds(), paddingTopLeft: paddingTopLeft, paddingBottomRight: paddingBottomRight

      # Add current position marker
      map.removeLayer currentPositionMarker unless currentPositionMarker is null
      currentPositionMarker = Util.createPositionMarker e.latlng
      map.addLayer currentPositionMarker, true

      # Select previously selected POI again
      selectedMarker = null
      selectedMarkerZIndex = 0
      maxZIndex = 0
      selectPoi $scope.selectedPoi if $scope.selectedPoi?

      $scope.loading = false
    , (error) ->
      alert "Sorry, could not load locations. #{JSON.stringify error}"
      console.error "Failed API call: #{error}"
      $scope.loading = false

  map.on "locationerror", (e) ->
    alert "Sorry, cannot determine position."
    console.error "Failed to get current position: {e}"
    $scope.loading = false

  map.on "zoomend", (e) ->
    selectPoi $scope.selectedPoi if $scope.selectedPoi?

  map.on "click", (e) ->
    unselectPois()
    $scope.$apply()

  oms.addListener "spiderfy", (spiderfied, others) ->
    unselectPois()
    _.each others, (marker) ->
      marker._icon.className = marker._icon.className + " disabled"

    spiderfiedMarkers = spiderfied

  oms.addListener "unspiderfy", (unspiderfied, others) ->
    _.each venuesLayer.getLayers(), (marker) ->
      marker._icon.className = marker._icon.className.replace " disabled", ""

    unselectPois()
    spiderfiedMarkers = null

  document.addEventListener "visibilitychange", visibilityChanged, false
