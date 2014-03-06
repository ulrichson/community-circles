# util = window.Util
mapApp = angular.module("mapApp", ["communityCirclesApp", "communityCirclesUtil", "hmTouchEvents", "CommunityModel", "ngAnimate"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, $compile, app, Util, CommunityRestangular) ->

  markerDiameter = 60
  mapPreviewHeight = 80
  communityOpacity = 0.2
  animationDuration = 1
  communityRenderingEnabled = true

  communities = []
  contributions = []

  currentPositionLayer = null
  currentPositionMarker = null

  map = new L.Map "map",
    center: Util.lastKnownPosition()
    zoom: 16
    zoomControl: false

  $scope.loading = false
  $scope.contributionSelected = false;
  $scope.contribution = {}

  L.Map.prototype.panToOffset = (latlng, offset, options) ->
    x = this.latLngToContainerPoint(latlng).x - offset[0]
    y = this.latLngToContainerPoint(latlng).y - offset[1]
    point = this.containerPointToLatLng [x, y]
    return this.setView point, this._zoom, { pan: options }

  #-----------------------------------------------------------------------------
  # MAP EVENTS
  #-----------------------------------------------------------------------------
  map.on "locationfound", (e) ->
    $scope.$apply -> $scope.loading = false
    map.setView e.latlng
    drawCommunities e.latlng
    drawCurrentPositionMarker e.latlng

  map.on "locationerror", (e) ->
    $scope.$apply -> $scope.loading = false
    alert "Could not determine position, please verify that the app has permission to use location services."
    console.error "Could not determine position (code=#{e.code}). #{e.message}"

  map.on "viewreset", ->
    renderCommunityCircles()

  map.on "error", (e) ->
    $scope.$apply -> $scope.loading = false
    alert "Sorry, the map cannot be loaded at the moment"
    console.error "Leaflet error: #{e.message}"

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  locate = ->
    $scope.loading = true
    map.locate()

  projectCircle = (ll, r) ->
    lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
    ll2 = new L.LatLng(ll.lat, ll.lng - lr)
    point = map.latLngToLayerPoint(ll)
    radius = point.x - map.latLngToLayerPoint(ll2).x
    return point: point, radius: radius

  renderCommunityCircles = ->
    return if contributions.length is 0 or not communityRenderingEnabled

    unitedCircles = null
    _.each contributions, (element) ->
      latlng = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
      projectedCircle = projectCircle latlng, element.properties.radius
      
      circle = new paper.Path.Circle(new paper.Point(projectedCircle.point.x, projectedCircle.point.y), projectedCircle.radius)

      if unitedCircles is null
        unitedCircles = circle
      else
        unitedCircles = unitedCircles.unite circle

    circlesPathElement = unitedCircles.exportSVG()
    circlesPathElement.setAttribute "fill", "#00c8c8"
    circlesPathElement.setAttribute "fill-opacity", communityOpacity
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
  drawCommunities = (position) ->
    $scope.loading = true

    fakeAsyncCallback = (data) ->
      $scope.$apply -> $scope.loading = false
      contributions = data.features
      
      # Contributions and clustering
      markers = new L.MarkerClusterGroup()
      # markers = new L.LayerGroup()
      _.each data.features, (element) ->
        latlng = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
        svgMarker = new L.SVGMarker latlng,
          svg: "/icons/contribution/#{element.properties.type}.svg"
          size: new L.Point markerDiameter, markerDiameter
          afterwards: (domNode) ->
            contribution = element.properties

            # Remove previous created health bar
            d3.select(domNode).select(".contribution-health").remove()

            # Create health progress bar
            healthProgress = d3.select(domNode)
              .attr("class", "leaflet-zoom-hide")
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

            domParent = healthProgress.node().parentNode
            domParent.setAttribute "hm-tap", "showContributionDetail(#{contribution.id})"
            $compile(domParent) $scope

        markers.addLayer svgMarker

        # Register click event
        # svgMarker.on "click", contributionMarkerClicked
      
      map.addLayer markers

      # Community Circles
      renderCommunityCircles()

    fakeAsyncCallback(contributionsGeoJSON)

  drawCurrentPositionMarker = (latlng) ->
    # Clean up
    if currentPositionLayer isnt null
      currentPositionLayer.removeLayer currentPositionMarker unless currentPositionMarker is null
      map.removeLayer currentPositionLayer

    # Add marker
    currentPositionLayer = new L.LayerGroup()
    currentPositionMarker = new L.SVGMarker latlng,
      svg: "/icons/current_position.svg"
      size: new L.Point markerDiameter, markerDiameter

    currentPositionLayer.addLayer currentPositionMarker
    map.addLayer currentPositionLayer

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
    locate()

  $scope.openContribution = ->
    webView = new steroids.views.WebView "/views/contribution/show.html?id=#{$scope.contribution.properties.id}"
    steroids.layers.push webView

  $scope.showContributionDetail = (id) ->
    console.debug "Showing contribution with id #{id}"
    $scope.contributionSelected = true
    $scope.contribution = _.filter(contributions, (e) -> return e.properties.id == id )[0]
    $scope.contribution.properties.area = Util.formatAreaHtml $scope.contribution.properties.radius * $scope.contribution.properties.radius * Math.PI
    
    # Pan map to contribution and offset it on top
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    offset = [0, -(map.getSize().y / 2 - mapPreviewHeight / 2)]
    x = map.latLngToContainerPoint(latlng).x - offset[0]
    y = map.latLngToContainerPoint(latlng).y - offset[1]
    point = map.containerPointToLatLng [x, y]
    map.setView point#,
      # animate: true
      # duration: animationDuration;

    # map.dragging.disable()
    # map.touchZoom.disable()
    # map.doubleClickZoom.disable()
    # map.scrollWheelZoom.disable()
    # map.tap.disable() if map.tap

    # drawCommunities point

  $scope.hideContributionDetail = ->
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    map.panTo latlng,
      animate: true
      duration: animationDuration;
    map.dragging.enable()
    map.touchZoom.enable()
    map.doubleClickZoom.enable()
    map.scrollWheelZoom.enable()
    map.tap.enable() if map.tap
    $scope.contributionSelected = false
 
  #-----------------------------------------------------------------------------
  # GLOBAL EVENTS
  #-----------------------------------------------------------------------------
  window.addEventListener "message", (event) ->
    
    # reload data on message with reload status
    # drawCommunities() if event.data.status is "reload"
    return

  #-----------------------------------------------------------------------------
  # INITIALIZE
  #-----------------------------------------------------------------------------
  
  # Background service
  backgroundWebView = new steroids.views.WebView "backgroundServices.html"
  backgroundWebView.preload()

  # Paper for SVG union on community rendering
  paper.setup()

  tileLayer = L.tileLayer "http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png",
    detectRetina: true
    reuseTiles: true
    unloadInvisibleTiles: false
    subdomains: "a b c d".split " "

  tileLayer.addTo map
  
  #-----------------------------------------------------------------------------
  # RUN
  #-----------------------------------------------------------------------------
  document.ontouchmove = (e) -> e.preventDefault()
  locate()