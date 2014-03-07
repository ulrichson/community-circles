# util = window.Util
mapApp = angular.module("mapApp", ["communityCirclesApp", "communityCirclesUtil", "hmTouchEvents", "CommunityModel", "ngAnimate"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, $compile, app, Util, CommunityRestangular) ->

  markerDiameter = 60
  mapPreviewHeight = 80
  communityOpacity = 0.2
  animationDuration = 0.5

  communities = []
  contributions = []

  currentPositionLayer = null
  currentPositionMarker = null
  zoomBefore = null

  map = new L.Map "map",
    center: Util.lastKnownPosition()
    zoom: 16
    zoomControl: false

  $scope.loading = false
  $scope.contributionSelected = false;
  $scope.contribution = {}

  #-----------------------------------------------------------------------------
  # COMMUNITY CIRCLE LAYER
  #-----------------------------------------------------------------------------
  CommunityCirclesLayer = L.Path.extend
    initialize: (contributions, options) ->
      L.Path.prototype.initialize.call this, options
      this._contributions = contributions

    getPathString: ->
      return this._createPath()

    _projectCircle: (ll, r) ->
      lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
      ll2 = new L.LatLng(ll.lat, ll.lng - lr)
      point = map.latLngToLayerPoint(ll)
      radius = point.x - map.latLngToLayerPoint(ll2).x
      return point: point, radius: radius

    _createPath: ->
      self = this
      circlesPathElement = null
      unitedCircles = null
      _.each this._contributions, (element) ->
        latlng = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
        projectedCircle = self._projectCircle latlng, element.properties.radius
      
        circle = new paper.Path.Circle(new paper.Point(projectedCircle.point.x, projectedCircle.point.y), projectedCircle.radius)

        if unitedCircles is null
          unitedCircles = circle
        else
          unitedCircles = unitedCircles.unite circle

        circlesPathElement = unitedCircles.exportSVG()

      return circlesPathElement.getAttribute "d"

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

  map.on "error", (e) ->
    $scope.$apply -> $scope.loading = false
    alert "Sorry, the map cannot be loaded at the moment"
    console.error "Leaflet error: #{e.message}"

  contributionMarkerClicked = (e) ->
    id = parseInt e.target._container.dataset.contribution_id
    $scope.showContributionDetail id

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  locate = ->
    $scope.loading = true
    map.locate()

  refreshMap = (position) ->
    # console.debug "Received position #{position.coords.latitude} #{position.coords.longitude}, accuracy: #{position.coords.accuracy}."

  createContributionMarker = (element) ->
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
        domParent.dataset.contribution_id = contribution.id

    return svgMarker

  # Helper function for loading map data with spinner
  drawCommunities = (position) ->
    $scope.loading = true

    fakeAsyncCallback = (data) ->
      $scope.$apply -> $scope.loading = false
      contributions = data.features

      # Community Circles
      circles = new CommunityCirclesLayer contributions,
        fill: true
        stroke: false
        fillColor: "#00c8c8"
        fillOpacity: communityOpacity
      map.addLayer circles
      
      # Contributions and clustering
      markers = new L.MarkerClusterGroup()
      _.each data.features, (element) ->
        contributionMarker = createContributionMarker element
        contributionMarker.on "click", contributionMarkerClicked
        markers.addLayer contributionMarker
      
      map.addLayer markers

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
    $scope.contributionSelected = true
    $scope.contribution = _.filter(contributions, (e) -> return e.properties.id is id)[0]
    $scope.contribution.properties.area = Util.formatAreaSqKm $scope.contribution.properties.radius * $scope.contribution.properties.radius * Math.PI
    
    zoomBefore = map.getZoom()

    # Pan map to contribution and offset it on top
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    offset = [0, -(map.getSize().y / 2 - mapPreviewHeight / 2)]
    x = map.latLngToContainerPoint(latlng).x - offset[0]
    y = map.latLngToContainerPoint(latlng).y - offset[1]
    point = map.containerPointToLatLng [x, y]
    map.panTo point,
      animate: true
      duration: animationDuration
    
    map.dragging.disable()
    map.touchZoom.disable()
    map.doubleClickZoom.disable()
    map.scrollWheelZoom.disable()
    map.tap.disable() if map.tap

    $scope.$apply()

  $scope.hideContributionDetail = ->
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    map.panTo latlng,
      animate: true
      duration: animationDuration
    
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
    subdomains: "a b c d".split " "

  tileLayer.addTo map
  
  #-----------------------------------------------------------------------------
  # RUN
  #-----------------------------------------------------------------------------
  # Prevents that WebView is dragged
  document.ontouchmove = (e) -> e.preventDefault()

  # Prevent that map doesn't receive click events from contribution overlay
  L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]
  locate()