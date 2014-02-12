mapApp = angular.module("mapApp", ["communityCirclesApp", "hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, app) ->
  $scope.locating = false
  $scope.loading = false

  #-----------------------------------------------------------------------------
  # INITIALIZE BACKGROUND SERVICE !!!MOVE SOMEWHERE ELSE!!!
  #-----------------------------------------------------------------------------
  # backgroundWebView = new steroids.views.WebView "backgroundServices.html"
  # backgroundView.preload()

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
    app.mapId,
    zoomControl: false
    tileLayer:
      detectRetina: true

  map.on "ready", ->
    loadMap()

  map.on "error", (error) ->
    console.error "Mapbox error: #{error}"

  #-----------------------------------------------------------------------------
  # FUNCTIONS
  #-----------------------------------------------------------------------------  
  refreshMap = (position) ->
    console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  # Helper function for loading map data with spinner
  loadMap = ->
    $scope.loading = true
    navigator.geolocation.getCurrentPosition (position) ->
      $scope.$apply ->
        $scope.loading = false
      map.setView [position.coords.latitude, position.coords.longitude], 20

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
  # UI EVENTS
  #-----------------------------------------------------------------------------
  $scope.testLocalNotification = ->
    if window.plugin.notification.local
      window.plugin.notification.local.add
        message: "Hello World"
    else
      console.warn "Local notifications are not supported"

  $scope.newContribution = ->
    steroids.layers.push new steroids.views.WebView "/views/contribution/new.html"
    # steroids.modal.show new steroids.views.WebView "/views/contribution/new.html"

  $scope.locate = ->
    $scope.locating = true
    navigator.geolocation.getCurrentPosition (position) ->
      $scope.$apply -> 
        $scope.locating = false
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
 
  #-----------------------------------------------------------------------------
  # GENERAL EVENTS
  #-----------------------------------------------------------------------------
  window.addEventListener "message", (event) ->
    
    # reload data on message with reload status
    loadMap() if event.data.status is "reload"