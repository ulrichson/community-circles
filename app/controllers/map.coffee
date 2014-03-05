mapApp = angular.module("mapApp", ["communityCirclesApp", "hmTouchevents", "CommunityModel"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, $compile, app, CommunityRestangular) ->

  markerDiameter = 32

  communities = []
  contributions = []

  $scope.locating = false
  $scope.loading = false

  paper.setup()

  currentPositionLayer = null
  currentPositionMarker = null

  #-----------------------------------------------------------------------------
  # INITIALIZE BACKGROUND SERVICE
  #-----------------------------------------------------------------------------
  backgroundWebView = new steroids.views.WebView "backgroundServices.html"
  backgroundWebView.preload()

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

  #-----------------------------------------------------------------------------
  # MAP EVENTS
  #-----------------------------------------------------------------------------
  map.on "ready", ->
    loadMap()
    $scope.locate()

  map.on "viewreset", ->
    createCommunityCircles()

  map.on "error", (error) ->
    alert "Sorry, the map cannot be loaded at the moment"
    console.error "Mapbox error: #{error}"

  map.on "popupopen", (e) ->
    # DOM elements created by Leaflet.js need to be compiled for Angular.js
    $compile(e.popup._contentNode) $scope

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  projectCircle = (ll, r) ->
    lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
    ll2 = new L.LatLng(ll.lat, ll.lng - lr)
    point = map.latLngToLayerPoint(ll)
    radius = point.x - map.latLngToLayerPoint(ll2).x
    return point: point, radius: radius

  createCommunityCircles = ->
    return null if contributions.length is 0

    unitedCircles = null
    _.each contributions, (element) ->
      latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
      projectedCircle = projectCircle latlan, element.properties.radius
      
      circle = new paper.Path.Circle(new paper.Point(projectedCircle.point.x, projectedCircle.point.y), projectedCircle.radius)

      if unitedCircles is null
        unitedCircles = circle
      else
        unitedCircles = unitedCircles.unite circle

    circlesPathElement = unitedCircles.exportSVG()
    circlesPathElement.setAttribute "fill", "#00c8c8"
    circlesPathElement.setAttribute "fill-opacity", "0.2"
    circlesPathElement.setAttribute "class", "community-circle"

    container = document.getElementsByClassName("leaflet-overlay-pane")[0].firstChild
    if document.getElementsByClassName("community-circle").length is 0
      container.insertBefore circlesPathElement, container.firstChild
    else
      container.replaceChild circlesPathElement, container.firstChild

    return circlesPathElement

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
        contributions = data.features
        
        # Contributions and clustering
        markers = new L.MarkerClusterGroup()

        _.each data.features, (element) ->
          latlan = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
          svgMarker = new L.SVGMarker latlan,
            svg: "/icons/contribution/#{element.properties.type}.svg"
            size: new L.Point markerDiameter, markerDiameter
            afterwards: (domNode) ->
              contribution = element.properties

              # Remove previous created health bar
              d3.select(domNode).select(".contribution-health").remove()

              # Create health progress bar
              healthProgress = d3.select(domNode)
                .insert("svg:path", ":first-child")
                .attr("class", "contribution-health")
                .attr("width", markerDiameter)
                .attr("height", markerDiameter)
                .attr("fill", "#00c8c8")
                .attr("transform", "translate(#{markerDiameter / 2 }, #{markerDiameter / 2})")

              healthProgress.attr "d", d3.svg.arc()
                .startAngle(0)
                .endAngle(2 * Math.PI * contribution.health)
                .innerRadius(0)
                .outerRadius(markerDiameter / 2)

              healthProgress.node().parentNode.dataset.contribution_id = contribution.id

              # Contribution popup
              area = contribution.radius * contribution.radius * Math.PI
              # open(#{contribution.id})
              svgMarker.bindPopup "<p><strong>#{contribution.title}</strong> with an area of #{area}m<sup>2</sup></p><button class=\"btn btn-lg btn-block btn-primary\" hm-tap=\"open(#{contribution.id})\">Details</button>",
                offset: new L.Point 0, -markerDiameter / 2
                # autoPanPaddingTopLeft: [0,0]

          markers.addLayer svgMarker

          # Register click event
          svgMarker.on "click", (e) ->
            console.debug "Received click from contribution with id=#{e.target._container.dataset.contribution_id}"
        
        map.addLayer markers

        # Community Circles
        createCommunityCircles()

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

      latlan = new L.LatLng position.coords.latitude, position.coords.longitude
      map.setView latlan, app.mapInitZoom

      # Clean up
      if currentPositionLayer isnt null
        currentPositionLayer.removeLayer currentPositionMarker unless currentPositionMarker is null
        map.removeLayer currentPositionLayer

      # Add marker
      currentPositionLayer = new L.LayerGroup()
      currentPositionMarker = new L.SVGMarker latlan,
        svg: "/icons/current_position.svg"
        size: new L.Point markerDiameter, markerDiameter

      currentPositionLayer.addLayer currentPositionMarker
      map.addLayer currentPositionLayer

  $scope.open = (id) ->
    webView = new steroids.views.WebView "/views/contribution/show.html?id=#{id}"
    steroids.layers.push webView
 
  #-----------------------------------------------------------------------------
  # GLOBAL EVENTS
  #-----------------------------------------------------------------------------
  window.addEventListener "message", (event) ->
    
    # reload data on message with reload status
    loadMap() if event.data.status is "reload"