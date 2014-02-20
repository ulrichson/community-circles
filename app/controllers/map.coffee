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
      
      # communities = CommunityRestangular.one "contributions-geo"
      # communities.get().then (data) ->
      
      fakeAsyncCall = (data) ->
        # alert JSON.stringify d3.geo.bounds data
        # cl = communitiesLayer().data(data)
        # alert JSON.stringify cl
        # cl = d3layer().data data
        # map.addLayer cl

        console.debug "Received contributions: #{JSON.stringify data}"

        _.each data.features, (element) ->
          L.circle([element.geometry.coordinates[1], element.geometry.coordinates[0]], element.properties.radius, { stroke: false, fillColor: "#00c8c8"}).addTo map

        ### INLINE CIRCLE RENDERING ###
        # See http://bost.ocks.org/mike/leaflet/
        # and https://github.com/rclark/leaflet-d3-layer

        contributionIconRadius = 0

        svg = d3.select(map.getPanes().overlayPane).append("svg")
        g = svg.append("g").attr "class", "leaflet-zoom-hide"
        # bounds = d3.geo.bounds data
        transform = d3.geo.transform
          point: (x, y) ->
            point = map.latLngToLayerPoint new L.LatLng y, x
            this.stream.point point.x, point.y

        path = d3.geo.path()
          .projection(transform)
          .pointRadius (d) ->
            return 20
            # return contributionIconRadius
            #return 0.1 * d.properties.radius

        bounds = path.bounds data
        feature = g.selectAll("path")
          .data(data.features)
          .enter()
          .append("path")
          #.append("circle")
          .style("fill", "00c8c8")
          # .append("circle")
          # .datum( (d) -> console.log JSON.stringify d )
          # .attr("opacity", "0.5")

        reset = ->
          # topLeft = bounds[0]
          # bottomRight = bounds[1]
          # svg.attr("width", bottomRight[0] - topLeft[0] + 2 * contributionIconRadius)
          #   .attr("height", bottomRight[1] - topLeft[1] + 2 * contributionIconRadius)
          #   .style("left", (topLeft[0] - contributionIconRadius) + "px")
          #   .style("top", (topLeft[1] + contributionIconRadius) + "px")
          # # svg.style("left", topLeft[0] + "px").style("top", topLeft[1] + "px")
          # g.attr("transform", "translate(" + - (topLeft[0] - contributionIconRadius) + "," + -(topLeft[1] + contributionIconRadius) + ")")
          svg.attr("width", map.getSize().x).attr("height", map.getSize().y)
          feature.attr("d", path)

        # map.on "viewreset", reset
        # reset()

        # Approach by http://bl.ocks.org/mbostock/899711
        # NOT DONE

        # Clustering
        # markers = new L.MarkerClusterGroup()
        markers = new L.LayerGroup()
        _.each data.features, (element) ->
          latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
          markers.addLayer new L.circleMarker latlan,
            radius: 20
            fillColor: "#00c8c8"
            fillOpacity: 1
            weight: 0

          markers.addLayer new L.SVGMarker latlan,
            svg: "/icons/contribution-type/#{element.properties.type}.svg"
            size: new L.Point 15, 15
            fill: "#ffffff"

          markers.addLayer new L.RadialBarChartMarker latlan,
            data:
              "health": Math.random() * 100
            chartOptions:
              "health":
                color: "#333333"
                fillColor: "#00c8c8"
                minValue: 0
                maxValue: 100
                maxHeight: 100
            backgroundStyle: null
            clickable: false
            fillColor: "#00c8c8"
            fillOpacity: 1
            weight: 0
            gradient: false
            dropshadow: false
            radius: 20
            rotation: -90
          
        map.addLayer markers

      
      fakeAsyncCall(contributionsGeoJSON)
      # console.log JSON.stringify contributionsGeoJSON

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