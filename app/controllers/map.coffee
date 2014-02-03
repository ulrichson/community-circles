mapApp = angular.module("mapApp", ["MapModel", "hmTouchevents"])

# Index: http://localhost/views/map/index.html
mapApp.controller "IndexCtrl", ($scope, MapRestangular) ->
  map = L.mapbox.map "map",
    "examples.map-y7l23tes",
    tileLayer:
      detectRetina: true

  map.on "ready", ->
    $scope.loadMap()

  map.on "error", (error) ->
    console.error "Mapbox error: #{error}"

  $scope.newContribution = ->
    # newContributionView = new steroids.views.WebView "/views/contribution/new.html",
    # console.debug "newContributionView=#{JSON.stringify newContributionView}"
    # console.debug "__newContributionView=#{JSON.stringify newContributionView}"
    # steroids.layers.push
    #   view: newContributionView
    #   onFailure: (error) ->
    #     console.error "Could not push the view: #{error.errorDescription}"
    steroids.layers.push new steroids.views.WebView "/views/contribution/new.html"
  
  # Helper function for loading map data with spinner
  $scope.loadMap = ->
    $scope.loading = false
    navigator.geolocation.getCurrentPosition (position) ->
      # $scope.loading = false
      # $scope.$apply
      console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."
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
      L.circle([position.coords.latitude, position.coords.longitude], 50, { stroke: false, fillColor: "#00a8b3"}).addTo map

      # Draw circle with GPS accuracy
      L.circle([position.coords.latitude, position.coords.longitude], position.coords.accuracy, { opacity: 0.1, fillOpacity: 0.1 }).addTo map
    , (error) ->
      # $scope.loading = false
      # $scope.$apply
      console.error "Could not determine position. #{error.message} (#{error.code})."
      alert "Could not determine position, please verify that the app has permission to use location services."
 
  # Get notified when an another webview modifies the data and reload
  window.addEventListener "message", (event) ->
    
    # reload data on message with reload status
    $scope.loadMap() if event.data.status is "reload"

  # -- Native navigation
  
  # Set navigation bar..
  steroids.view.navigationBar.show "Community Circles"

  buttonRefresh = new steroids.buttons.NavigationBarButton
  buttonRefresh.title = "Refresh"
  buttonRefresh.onTap = ->
    $scope.loadMap()

  steroids.view.navigationBar.setButtons
    right: [buttonRefresh]