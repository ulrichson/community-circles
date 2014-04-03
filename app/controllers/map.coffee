# util = window.Util
mapApp = angular.module "mapApp", [
  "communityCirclesApp",
  "communityCirclesGame",
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch",
  "CommunityModel",
  "ngAnimate",
  "angularMoment",
  "swipe"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/map/index.html
#------------------------------------------------------------------------------- 
mapApp.controller "IndexCtrl", ($scope, $compile, app, Game, Util, Log, CommunityRestangular) ->

  markerDiameter = 40
  mapPreviewHeight = 80
  communityOpacity = 0.4
  communityColor = "#3FD1D1"
  contributionColor = "#00A8B3"
  baseAnimationDuration = 500
  animationDuration = 0.3
  pulseDuration = baseAnimationDuration * 6

  # Detect double-clicks for contribution marker
  contributionClickCount = 0

  communities = []
  contributions = []

  # Map Layer
  communitiesLayer = null
  contributionsLayer = null

  contributionMarkers = []
  selectedContributionMarker = null
  currentPositionMarker = null

  # Map controls
  locateControl = null
  newContributionControl = null

  map = new L.Map "map",
    center: Util.lastKnownPosition()
    zoom: 14
    zoomControl: false

  $scope.loading = false
  $scope.contributionSelected = false;
  $scope.contribution = {}

  #-----------------------------------------------------------------------------
  # CUSTOM MAP CONTROLS
  #-----------------------------------------------------------------------------
  LocateControl = L.Control.extend
    options:
      position: "bottomleft"

    onAdd: (map) ->
      this._container = L.DomUtil.create "span", "cc-locate-control map-button fa-stack fa-lg fa-2x"
      this._container.appendChild L.DomUtil.create "i", "fa fa-circle-o fa-stack-2x"
      this._container.appendChild L.DomUtil.create "i", "fa fa-location-arrow fa-stack-1x"
      L.DomEvent.addListener this._container, "click", (e) ->
        L.DomEvent.stopPropagation e
        map.setView Util.lastKnownPosition()

      return this._container

  NewContributionControl = L.Control.extend
    options:
      position: "bottomleft"

    onAdd: (map) ->
      this._container = L.DomUtil.create "span", "cc-locate-control map-button fa-stack fa-lg fa-2x"
      this._container.appendChild L.DomUtil.create "i", "fa fa-circle-o fa-stack-2x"
      this._container.appendChild L.DomUtil.create "i", "fa fa-plus fa-stack-1x"
      L.DomEvent.addListener this._container, "click", (e) ->
        L.DomEvent.stopPropagation e
        $scope.newContribution()

      return this._container
      
  #-----------------------------------------------------------------------------
  # MAP EVENTS
  #-----------------------------------------------------------------------------
  map.on "layeradd", (e) ->
    if e.layer.feature? and e.layer.feature.properties.health < Game.healthAlertThreshold
      latlng = e.layer._latlng
      radius = e.layer.feature.properties.radius
      iconNode = d3.select(e.layer._icon)
      svgElement = d3.select e.layer._icon.getElementsByClassName("contribution-health")[0]

      # Blink
      e.layer.blinkInterval = setInterval ->
        blink svgElement, baseAnimationDuration if map.getBounds().pad(0.1).contains latlng # don't animate when marker is outside
      , baseAnimationDuration

      # Pulse
      e.layer.pulseInterval = setInterval ->
        tripplePulse iconNode, latlng, radius if map.getBounds().pad(0.1).contains latlng # don't animate when marker is outside
      , pulseDuration
      tripplePulse iconNode, latlng, radius

  map.on "layerremove", (e) ->
    clearInterval e.layer.pulseInterval if e.layer.pulseInterval?
    clearInterval e.layer.blinkInterval if e.layer.blinkInterval?

  map.on "locationfound", (e) ->
    Log.i "Location found: #{e.latlng.lat}, #{e.latlng.lng}"
    $scope.$apply -> $scope.loading = false
    drawCommunities e.latlng
    updateCurrentPositionMarker e.latlng

  map.on "locationerror", (e) ->
    $scope.$apply -> $scope.loading = false
    Log.w "Could not determine position (code=#{e.code}). #{e.message}"

  # map.on "zoomstart", (e) ->
  #   # Fade out all pulse animations
  #   pulses = d3.selectAll(".contribution-pulse-container")
  #   # console.log pulses
  #   pulses.transition()
  #     .style("opacity", 0)
  #     .duration(100)

  map.on "error", (e) ->
    $scope.$apply -> $scope.loading = false
    alert "Sorry, the map cannot be loaded at the moment"
    Log.e "Leaflet error: #{e.message}"

  contributionMarkerClicked = (e) ->
    # Log.d "click"
    contributionClickCount++
    targetBoundingBox = e.target._icon.getBoundingClientRect()

    # 200ms delay to wait for possible doube-clicks.
    # Allows to double-click zoom into the map, although marker was clicked.
    setTimeout ->
      # Check if click is inside marker
      if contributionClickCount is 1 #and
      # targetBoundingBox.left < e.originalEvent.clientX < targetBoundingBox.right and
      # targetBoundingBox.top < e.originalEvent.clientY < targetBoundingBox.bottom
        if not selectedContributionMarker
          # Hide everything, except selected contribution
          map.removeControl locateControl
          map.removeControl newContributionControl
          map.removeLayer currentPositionMarker
          map.removeLayer communitiesLayer
          _.each contributionMarkers, (marker) ->
            if marker is e.target
              selectedContributionMarker = e.target
            else
              contributionsLayer.removeLayer marker

          id = parseInt e.target.feature.properties.id
          $scope.showContributionDetail id
        else
          $scope.hideContributionDetail()
          $scope.$apply()
      contributionClickCount = 0
    , 200

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  projectCircle = (ll, r) ->
    lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
    ll2 = new L.LatLng(ll.lat, ll.lng - lr)
    point = map.latLngToLayerPoint(ll)
    radius = point.x - map.latLngToLayerPoint(ll2).x
    return point: point, radius: radius

  blink = (node, duration) ->
    opacity = if node.style("opacity") < 0.01 then 1 else 0
    node.transition()
     .style("opacity", opacity)
     .duration(duration)

  tripplePulse = (n, ll, r) ->
    radius = projectCircle(ll, r).radius
    if radius > markerDiameter / 2
      point = map.latLngToLayerPoint ll
      pulse n, point, radius, pulseDuration
      setTimeout ->
        pulse n, point, radius, pulseDuration
      , 200
      setTimeout ->
        pulse n, point, radius, pulseDuration
      , 400

  pulse = (node, point, radius, duration, strokeWidth = 1.5) ->
    parent = d3.select node.node().parentNode
    svg = parent.append("svg")
    svg.attr("width", radius * 2)
      .attr("height", radius * 2)
      .attr("class", "contribution-pulse-container")
      .style("position", "absolute")
      .style("left", -radius)
      .style("top", -radius)
      .style("z-index", -1)
      # .style("-webkit-transform", L.DomUtil.getTranslateString point)
      .style("-webkit-transform", node.style("-webkit-transform"))
      .append("circle")
      .attr("class", "contribution-pulse")
      .attr("r", markerDiameter / 2)
      .attr("cx", radius)
      .attr("cy", radius)
      .attr("fill-opacity", 0)
      .attr("stroke", contributionColor)
      .attr("stroke-width", strokeWidth)
      .transition()
      .attr("r", radius - strokeWidth / 2)
      .style("opacity", 0)
      .ease("cubic-out")
      .duration(duration)
      .each "end", ->
        svg.remove()

  locate = ->
    $scope.loading = true
    map.locate
      enableHighAccuracy: true
      watch: true

  createContributionMarker = (feature, latlng) ->
    healthProgress = d3.select(document.createElement("div"))
    healthProgress.append("svg")
      .attr("class", "contribution-health")
      .attr("width", markerDiameter)
      .attr("height", markerDiameter)
      .append("path")
      .attr("fill", contributionColor)
      .attr("transform", "translate(#{markerDiameter / 2 }, #{markerDiameter / 2})")
      .attr("d", d3.svg.arc()
        .startAngle(0)
        .endAngle(2 * Math.PI * feature.properties.health)
        .innerRadius(0)
        .outerRadius(markerDiameter / 2))

    svgMarker = new L.Marker latlng,
      icon: L.divIcon
        className: "contribution-marker"
        iconSize: [markerDiameter, markerDiameter]
        html: "#{healthProgress.node().innerHTML}<div class=\"contribution-icon contribution-icon-#{feature.properties.type}\"></div>"
    return svgMarker

  # Helper function for loading map data with spinner
  drawCommunities = (position) ->
    $scope.loading = true

    map.removeLayer communitiesLayer unless communitiesLayer is null
    map.removeLayer contributionsLayer unless contributionsLayer is null

    contributionMarkers = []

    fakeAsyncCallback = (data) ->
      $scope.$apply -> $scope.loading = false
      contributions = data.features

      communitiesLayer = L.TileLayer.maskCanvas
        color: communityColor;
        lineWidth: 0
        noMask: true
        opacity: communityOpacity

      communitiesLayer.setData data
      map.addLayer communitiesLayer
      
      # Contributions and clustering
      contributionsLayer = new L.MarkerClusterGroup
        iconCreateFunction: (cluster) ->
          return new L.DivIcon
            html: "<div class=\"contribution-marker-cluster\"><span>#{cluster.getChildCount()}</span></div>"
        maxClusterRadius: markerDiameter + 5
        removeOutsideVisibleBounds: true
        showCoverageOnHover: false
        zoomToBoundsOnClick: false

      geoJsonLayer = L.geoJson data,
        onEachFeature: (feature, layer) ->
          layer.on "click", contributionMarkerClicked
        pointToLayer: (feature, latlng) ->
          contributionMarker = createContributionMarker feature, latlng
          contributionMarkers.push contributionMarker
          return contributionMarker

      contributionsLayer.addLayer geoJsonLayer
      
      map.addLayer contributionsLayer

    fakeAsyncCallback contributionsGeoJSON

  updateCurrentPositionMarker = (latlng) ->
    # Clean up
    map.removeLayer currentPositionMarker unless currentPositionMarker is null

    currentPositionMarker = Util.createPositionMarker latlng, Game.initialRadius

    map.addLayer currentPositionMarker, true


  generateRandomContributions = (latLngBounds, n) ->
    ret = 
      type: "FeatureCollection"
      features: ( -> return 
      type: "Feature"
      geometry:
        type: "Point"
        coordinates: [
          latLngBounds.getSouthWest().lng + (latLngBounds.getNorthEast().lng - latLngBounds.getSouthWest().lng) * Math.random(),
          latLngBounds.getSouthWest().lat + (latLngBounds.getNorthEast().lat - latLngBounds.getSouthWest().lat) * Math.random()
        ]
      properties:
        id: i
        title: "Generated Title"
        type: ["issue", "idea", "poll", "opinion"][Math.round(Math.random() * 3)]
        mood: "happy"
        radius: Util.randomFromTo 50, 300
        health: Math.random()
        community_id: 0
        creator: "ulrichson"
        craeted: new Date()
      ) for i in [1..n]

  #-----------------------------------------------------------------------------
  # UI EVENTS
  #-----------------------------------------------------------------------------
  $scope.newContribution = ->
    steroids.layers.push new steroids.views.WebView
      location: "/views/contribution/new.html"
      id: "newContributionView"

  $scope.locate = ->
    locate()

  $scope.openContribution = ->
    Util.send "showContributionController", "loadContribution", $scope.contribution.properties.id
    webView = new steroids.views.WebView 
      location: "/views/contribution/show.html"
      id: "mapShowContributionView"

    steroids.layers.push webView

  $scope.showContributionDetail = (id) ->
    $scope.contributionSelected = true
    $scope.contribution = _.filter(contributions, (e) -> return e.properties.id is id)[0]
    $scope.contribution.properties.area = Util.formatAreaSqKm $scope.contribution.properties.radius * $scope.contribution.properties.radius * Math.PI
    
    # Pan map to contribution and offset it on top
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    offset = [0, -(map.getSize().y / 2 - mapPreviewHeight / 2)]
    x = map.latLngToContainerPoint(latlng).x - offset[0]
    y = map.latLngToContainerPoint(latlng).y - offset[1]
    point = map.containerPointToLatLng [x, y]
    map.setView point
    
    map.dragging.disable()
    map.touchZoom.disable()
    map.doubleClickZoom.disable()
    map.scrollWheelZoom.disable()
    map.tap.disable() if map.tap

    $scope.$apply()

  $scope.hideContributionDetail = ->
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    map.setView latlng
    
    map.dragging.enable()
    map.touchZoom.enable()
    map.doubleClickZoom.enable()
    map.scrollWheelZoom.enable()
    map.tap.enable() if map.tap

    # Show contributions
    contributionsLayer.removeLayer selectedContributionMarker
    map.addLayer communitiesLayer
    _.each contributionMarkers, (marker) ->
      contributionsLayer.addLayer marker
    map.addLayer currentPositionMarker

    map.addControl locateControl
    map.addControl newContributionControl
    
    selectedContributionMarker = null
    $scope.contributionSelected = false

  #-----------------------------------------------------------------------------
  # INITIALIZE
  #-----------------------------------------------------------------------------
  
  # Preload WebViews

  # ATTENTION: this must only be called ONCE, therefore needs to be moved, if
  #            map view isn't the initial view anymore

  backgroundWebView = new steroids.views.WebView
    location: "backgroundServices.html"
    id: "backgroundService"
  backgroundWebView.preload()

  moodWebView = new steroids.views.WebView 
    location: "/views/mood/index.html"
    id: "moodView"
  moodWebView.preload()

  newContributionWebView = new steroids.views.WebView 
    location: "/views/contribution/new.html"
    id: "newContributionView"
  newContributionWebView.preload()

  showContributionWebView = new steroids.views.WebView
    location: "/views/contribution/show.html"
    id: "mapShowContributionView"
  showContributionWebView.preload()

  poiWebView = new steroids.views.WebView
    location: "/views/poi/index.html"
    id: "poiView"
  poiWebView.preload()

  tileLayer = Util.createTileLayer()

  tileLayer.addTo map

  locateControl = new LocateControl()
  newContributionControl = new NewContributionControl()

  map.addControl locateControl
  map.addControl newContributionControl
  
  #-----------------------------------------------------------------------------
  # RUN
  #-----------------------------------------------------------------------------
  # Prevents that WebView is dragged
  document.ontouchmove = (e) -> e.preventDefault()

  # Demo data
  # latLngBounds = L.latLngBounds new L.LatLng(48.3290194, 16.1749), new L.LatLng(48.078705, 16.570455)
  latLngBounds = map.getBounds()
  contributionsGeoJSON = generateRandomContributions latLngBounds, 50

  # Prevent that map doesn't receive click events from contribution overlay
  L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]
  locate()