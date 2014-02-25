mapApp = angular.module("mapApp", ["communityCirclesApp", "hmTouchevents", "CommunityModel"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, app, CommunityRestangular) ->

  communities = []

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
    console.error "Could not determine position: #{error.message} (#{error.code})"
  , enableHighAccuracy: true

  map = L.mapbox.map "map",
    app.mapId,
    zoomControl: app.mapShowZoomControls
    tileLayer:
      detectRetina: true

  map.on "ready", ->
    loadMap()

  map.on "error", (error) ->
    alert "Sorry, the map cannot be loaded at the moment"
    console.error "Mapbox error: #{error}"

  #-----------------------------------------------------------------------------
  # FUNCTIONS
  #-----------------------------------------------------------------------------  
  refreshMap = (position) ->
    # console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  # Helper function for loading map data with spinner
  loadMap = ->
    console.debug "loading map"
    $scope.loading = true

    # markers = new L.MarkerClusterGroup()
    # i = 0
    # while i < 3000
    #   i++
    #   latlan = new L.LatLng Math.random() * 90, Math.random() * 180
    #   marker = new L.SVGMarker latlan,
    #     svg: "http://upload.wikimedia.org/wikipedia/commons/8/8b/Green_Arrow_Up_Darker.svg"
    #     size: new L.Point 20, 20
    #   markers.addLayer marker
    
    # map.addLayer markers

    navigator.geolocation.getCurrentPosition (position) ->
      map.setView [position.coords.latitude, position.coords.longitude], app.mapInitZoom
      $scope.$apply -> $scope.loading = false

      fakeAsyncCall = (data) ->

        console.debug "Received contributions: #{JSON.stringify data}"

        _.each data.features, (element) ->
          L.circle([element.geometry.coordinates[1], element.geometry.coordinates[0]], element.properties.radius, { stroke: false, fillColor: "#00c8c8"}).addTo map

        # Clustering
        markers = new L.MarkerClusterGroup()
        map.addLayer markers
        # markers = new L.LayerGroup()
        _.each data.features, (element) ->
          latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
          # markers.addLayer new L.circleMarker latlan,
          #   radius: 20
          #   fillColor: "#00c8c8"
          #   fillOpacity: 1
          #   weight: 0

          markers.addLayer new L.SVGMarker latlan,
            svg: "/icons/contribution-type/simple.svg"
            # svg: "/icons/contribution-type/#{element.properties.type}.svg"
            # svg: "http://upload.wikimedia.org/wikipedia/commons/8/8b/Green_Arrow_Up_Darker.svg"
            size: new L.Point 25, 25

          # markers.addLayer new L.RadialBarChartMarker latlan,
          #   data:
          #     "health": Math.random() * 100
          #   chartOptions:
          #     "health":
          #       color: "#333333"
          #       fillColor: "#00c8c8"
          #       minValue: 0
          #       maxValue: 100
          #       maxHeight: 100
          #   backgroundStyle: null
          #   clickable: false
          #   fillColor: "#00c8c8"
          #   fillOpacity: 1
          #   weight: 0
          #   gradient: false
          #   dropshadow: false
          #   radius: 20
          #   rotation: -90
      fakeAsyncCall(contributionsGeoJSON)
    , (error) ->
      $scope.$apply -> $scope.loading = false
      console.error "Could not determine position. #{error.message} (#{error.code})."
      alert "Could not determine position, please verify that the app has permission to use location services."

  #-----------------------------------------------------------------------------
  # UI EVENTS
  #-----------------------------------------------------------------------------
  # $scope.testLocalNotification = ->
  #   if window.plugin.notification.local
  #     window.plugin.notification.local.add
  #       message: "Hello World"
  #   else
  #     console.warn "Local notifications are not supported"

  $scope.newContribution = ->
    steroids.layers.push new steroids.views.WebView "/views/contribution/new.html"

  $scope.locate = ->
    $scope.locating = true
    navigator.geolocation.getCurrentPosition (position) ->
      $scope.$apply -> 
        $scope.locating = false
      map.setView [position.coords.latitude, position.coords.longitude], app.mapInitZoom
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