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
  # COMMUNITIES LAYER
  #-----------------------------------------------------------------------------
  communitiesLayer = ->
    f = {}
    bounds = null
    feature = null
    div = d3.select(document.body).append("div").attr "class", "d3-vec"
    svg = div.append "svg"
    g = svg.append "g"

    f.parent = div.node()

    # f.project = (x) ->
    #   point = f.map.locationPoint { lat: x[1], lon: x[0] }
    #   return [point.x, point.y]

    # first = true
    f.draw = ->
      alert "Entered f.draw()"
      # if first
      #   svg.attr("width", f.map.dimensions.x).attr("height", f.map.dimensions.y).style("margin-left", "0px").style "margin-top", "0px"
      #   first = false

      # path = d3.geo.path().projection f.project
      # feature.attr "d", path

    f.data = (collection) ->
      bounds = d3.geo.bounds collection
      feature = g.selectAll("circle").data(collection.features).enter().append("circle").style "fill", "red"
      return f

    f.extent = ->
      return new MM.Extent new MM.Location bounds[0][1], bounds[0][0], new MM.Location bounds[1][1], bounds[1][0]

    return f

  #-----------------------------------------------------------------------------
  # FUNCTIONS
  #-----------------------------------------------------------------------------  
  refreshMap = (position) ->
    # console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  # Helper function for loading map data with spinner
  loadMap = ->
    $scope.loading = true
    navigator.geolocation.getCurrentPosition (position) ->
      $scope.$apply -> $scope.loading = false
      map.setView [position.coords.latitude, position.coords.longitude], app.mapInitZoom

      # communities = CommunityRestangular.all "contribution"
      # communities.getList().then (data) ->
      #   _.each data, (element) ->
      #     # alert element
      #     L.circle([element.location.latitude, element.location.longitude], element.radius, { stroke: false, fillColor: "#00a8b3"}).addTo map
      #   # L.featureLayer()
      #d3.json "http://localhost/data/demo/communities-geo.json", (collection) ->
      communities = CommunityRestangular.one "contributions-geo"
      communities.get().then (data) ->
        # alert JSON.stringify d3.geo.bounds data
        # cl = communitiesLayer().data(data)
        # alert JSON.stringify cl
        # cl = d3layer().data data
        # map.addLayer cl

        ### INLINE CIRCLE RENDERING ###
        # See http://bost.ocks.org/mike/leaflet/
        # and https://github.com/rclark/leaflet-d3-layer
        projectPoint = (x, y) ->
          point = map.latLngToLayerPoint new L.LatLng(y, x)
          return [point.x, point.y]

        # div = d3.select(document.body).append("div").attr "class", "d3-vec"
        svg = d3.select(map.getPanes().overlayPane).append "svg"
        g = svg.append("g").attr "class", "leaflet-zoom-hide"
        # bounds = d3.geo.bounds data
        transform = d3.geo.transform({point: projectPoint})
        path = d3.geo.path().projection(transform)
        bounds = path.bounds(collection)
        feature = g.selectAll("circle").data(collection.features).enter().append("circle").style "fill", "00c8c8"
        
        topLeft = bounds[0]
        bottomRight = bounds[1]
        svg.attr("width", bottomRight[0] - topLeft[0]).attr("height", bottomRight[1] - topLeft[1]).style("left", topLeft[0] + "px").style("top", topLeft[1] + "px")
        g.attr("transform", "translate(" + -topLeft[0] + "," + -topLeft[1] + ")")
        feature.attr("d", path)


      # Draw circle with GPS accuracy
      # L.circle([position.coords.latitude, position.coords.longitude], position.coords.accuracy, { opacity: 0.1, fillOpacity: 0.1 }).addTo map
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