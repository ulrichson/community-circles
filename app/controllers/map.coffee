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
  projectCircle = (ll, r) ->
    lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
    ll2 = new L.LatLng(ll.lat, ll.lng - lr)
    point = map.latLngToLayerPoint(ll)
    radius = point.x - map.latLngToLayerPoint(ll2).x
    return point: point, radius: radius

  refreshMap = (position) ->
    # console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  # Helper function for loading map data with spinner
  loadMap = ->
    console.debug "loading map"
    $scope.loading = true

    navigator.geolocation.getCurrentPosition (position) ->
      map.setView [position.coords.latitude, position.coords.longitude], app.mapInitZoom
      $scope.$apply -> $scope.loading = false

      fakeAsyncCall = (data) ->
        # console.debug "Received contributions: #{JSON.stringify data}"

        ### INLINE CIRCLE RENDERING ###
        # See http://bost.ocks.org/mike/leaflet/
        # Projection radius: https://github.com/Leaflet/Leaflet/blob/master/src/layer/vector/Circle.js#L33-63
        # Projection point: https://github.com/Leaflet/Leaflet/blob/master/src/layer/vector/CircleMarker.js#L43

        # svg = d3.select(map.getPanes().overlayPane).append("svg")
        # g = svg.append("g").attr "class", "leaflet-zoom-hide"
        # # bounds = d3.geo.bounds data
        # transform = d3.geo.transform
        #   point: (x, y) ->
        #     point = map.latLngToLayerPoint new L.LatLng y, x
        #     this.stream.point point.x, point.y

        # path = d3.geo.path()
        #   .projection(transform)
        #   .pointRadius (d) ->
        #     return d.properties.radius

        # bounds = path.bounds data
        # feature = g.selectAll("path")
        #   .data(data.features)
        #   .enter()
        #   .append("path")
        #   .style("fill", "00c8c8")
        #   .style("opacity", "0.5")
        #   # .append("circle")
        #   # .datum( (d) -> console.log JSON.stringify d )
        #   # .attr("opacity", "0.5")

        # reset = ->
        #   topLeft = bounds[0]
        #   bottomRight = bounds[1]
        #   svg.attr("width", bottomRight[0] - topLeft[0])
        #     .attr("height", bottomRight[1] - topLeft[1])
        #     .style("left", topLeft[0] + "px")
        #     .style("top", topLeft[1] + "px")
        #   g.attr("transform", "translate(" + - topLeft[0] + "," + -topLeft[1] + ")")
        #   svg.attr("width", map.getSize().x).attr("height", map.getSize().y)
        #   feature.attr("d", path)

        # map.on "viewreset", reset
        # reset()

        unitedCircles = null
        paper.setup()
        _.each data.features, (element) ->
          latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
          projectedCircle = projectCircle latlan, element.properties.radius
          console.debug "Projected contribution is #{JSON.stringify projectedCircle}"
          
          circle = new paper.Path.Circle(new paper.Point(projectedCircle.point.x, projectedCircle.point.y), projectedCircle.radius)

          if unitedCircles is null
            unitedCircles = circle
          else
            unitedCircles = unitedCircles.unite circle

        pathElement = unitedCircles.exportSVG()
        console.debug "United path is #{pathElement.getAttributeNode('d').value}"

        # console.debug document.getElementsByClassName("leaflet-overlay-pane")[0].outerHTML

        #document.getElementsByClassName("leaflet-overlay-pane")[0].getElementsByTagName("svg")[0].appendChild svgElement
        #d3.select(".leaflet-overlay-pane>svg:first-child").append svgElement.outerHTML
        svgElement = document.createElement "svg"
        svgElement.setAttribute "width", map.getSize().x
        svgElement.setAttribute "height", map.getSize().y
        document.getElementsByClassName("leaflet-overlay-pane")[0].appendChild svgElement

        pathElement.setAttribute "fill", "#00c8c8"
        svgElement.appendChild pathElement

        _.each data.features, (element) ->
          L.circle([element.geometry.coordinates[1], element.geometry.coordinates[0]], element.properties.radius, { "id": element.properties.id, className: "contribution-radius", stroke: false, fillColor: "#00c8c8"}).addTo map

        contributionDiameter = 32

        # Clustering
        markers = new L.MarkerClusterGroup()
        map.addLayer markers

        _.each data.features, (element) ->
          latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
          svgMarker = new L.SVGMarker latlan,
            svg: "/icons/contribution/#{element.properties.type}.svg"
            size: new L.Point contributionDiameter, contributionDiameter
            afterwards: (domNode) ->
              # Health progress bar

              # Remove previous created bar
              d3.select(domNode).select(".contribution-health").remove()

              healthProgress = d3.select(domNode)
                .insert("svg:path", ":first-child")
                .attr("class", "contribution-health")
                .attr("width", contributionDiameter)
                .attr("height", contributionDiameter)
                .attr("fill", "#00c8c8")
                .attr("transform", "translate(#{contributionDiameter / 2 }, #{contributionDiameter / 2})")

              healthProgress.attr "d", d3.svg.arc()
                .startAngle(0)
                .endAngle(2 * Math.PI * element.properties.health)
                .innerRadius(0)
                .outerRadius(contributionDiameter / 2)

          markers.addLayer svgMarker

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