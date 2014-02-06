mapApp = angular.module("mapApp", ["communityCirclesApp", "hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, app) ->
  #-----------------------------------------------------------------------------
  # FUNCTIONS
  #-----------------------------------------------------------------------------  
  refreshMap = (position) ->
    console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  # Helper function for loading map data with spinner
  loadMap = ->
    $scope.loading = false
    navigator.geolocation.getCurrentPosition (position) ->
      # $scope.loading = false
      # $scope.$apply
      map.setView [position.coords.latitude, position.coords.longitude], 20
      map.markerLayer.setGeoJSON
        type: "Feature"
        geometry:
          type: "Point"
          coordinates: [position.coords.longitude, position.coords.latitude]
        properties:
          "marker-color": "#00a8b3"
          "marker-symbol": "star-stroked"
      map.markerLayer.on "click", (e) ->
        console.debug "Panning to #{e.layer.getLatLng()}"
        map.panTo e.layer.getLatLng()

      # Draw circle with initial radius of contribution
      # L.circle([position.coords.latitude, position.coords.longitude], 50, { stroke: false, fillColor: "#00a8b3"}).addTo map

      # Draw circle with GPS accuracy
      # L.circle([position.coords.latitude, position.coords.longitude], position.coords.accuracy, { opacity: 0.1, fillOpacity: 0.1 }).addTo map
    , (error) ->
      # $scope.loading = false
      # $scope.$apply
      console.error "Could not determine position. #{error.message} (#{error.code})."
      alert "Could not determine position, please verify that the app has permission to use location services."

  #-----------------------------------------------------------------------------
  # INITIALIZE GEO
  #-----------------------------------------------------------------------------
  positionWatcherId = navigator.geolocation.watchPosition (positition) ->
    window.localStorage.setItem "lastKnownPosition", positition
    window.localStorage.setItem "lastKnownPositionTime", new Date().getTime()
    refreshMap positition
  , (error) ->
    console.error "Could not determine position. #{error.message} (#{error.code})."
  , enableHighAccuracy: true

  map = L.mapbox.map "map",
    "examples.map-y7l23tes",
    zoomControl: false
    tileLayer:
      detectRetina: true

  map.on "ready", ->
    loadMap()

  map.on "error", (error) ->
    console.error "Mapbox error: #{error}"

  #-----------------------------------------------------------------------------
  # UI EVENTS
  #-----------------------------------------------------------------------------
  $scope.testLocalNotification = ->
    if window.plugin.notification.local
      window.plugin.notification.local.add
        message: "Hello World"
    else
      console.warn "Local notifications are not supported"

  $scope.newContribution = ->
    # newContributionView = new steroids.views.WebView "/views/contribution/new.html",
    # console.debug "newContributionView=#{JSON.stringify newContributionView}"
    # console.debug "__newContributionView=#{JSON.stringify newContributionView}"
    # steroids.layers.push
    #   view: newContributionView
    #   onFailure: (error) ->
    #     console.error "Could not push the view: #{error.errorDescription}"
    steroids.modal.show new steroids.views.WebView "/views/contribution/new.html"
 
  #-----------------------------------------------------------------------------
  # GENERAL EVENTS
  #-----------------------------------------------------------------------------
  window.addEventListener "message", (event) ->
    
    # reload data on message with reload status
    loadMap() if event.data.status is "reload"