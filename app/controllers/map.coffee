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
  communityOpacity = 0.2
  animationDuration = 0.5

  communities = []
  contributions = []

  # Map Layer
  communitiesLayer = null
  contributionsLayer = null

  contributionMarkers = []
  selectedContributionMarker = null
  currentPositionMarker = null
  zoomBefore = null

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
  # COMMUNITY CIRCLE LAYER
  #-----------------------------------------------------------------------------
  # CommunityCirclesLayer = L.Path.extend
  #   initialize: (contributions, options) ->
  #     L.Path.prototype.initialize.call this, options
  #     this._contributions = contributions

  #   getPathString: ->
  #     return this._createPath()

  #   _createPath: ->
  #     self = this
  #     circlesPathElement = null
  #     unitedCircles = null
  #     _.each this._contributions, (element) ->
  #       latlng = new L.LatLng element.geometry.coordinates[1], element.geometry.coordinates[0]
  #       projectedCircle = projectCircle latlng, element.properties.radius
      
  #       circle = new paper.Path.Circle(new paper.Point(projectedCircle.point.x, projectedCircle.point.y), projectedCircle.radius)

  #       if unitedCircles is null
  #         unitedCircles = circle
  #       else
  #         unitedCircles = unitedCircles.unite circle

  #       circlesPathElement = unitedCircles.exportSVG()

  #     return circlesPathElement.getAttribute "d"

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
  map.on "locationfound", (e) ->
    Log.i "Location found: #{e.latlng.lat}, #{e.latlng.lng}"
    $scope.$apply -> $scope.loading = false
    drawCommunities e.latlng
    updateCurrentPositionMarker e.latlng

  map.on "locationerror", (e) ->
    $scope.$apply -> $scope.loading = false
    Log.w "Could not determine position (code=#{e.code}). #{e.message}"

  map.on "error", (e) ->
    $scope.$apply -> $scope.loading = false
    alert "Sorry, the map cannot be loaded at the moment"
    Log.e "Leaflet error: #{e.message}"

  contributionMarkerClicked = (e) ->
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

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  projectCircle = (ll, r) ->
    lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat)
    ll2 = new L.LatLng(ll.lat, ll.lng - lr)
    point = map.latLngToLayerPoint(ll)
    radius = point.x - map.latLngToLayerPoint(ll2).x
    return point: point, radius: radius

  locate = ->
    $scope.loading = true
    map.locate
      enableHighAccuracy: true
      watch: true

  createContributionMarker = (feature, latlng) ->
    #     # Indicate low health
    #     baseDuration = 500
    #     blink = (parent, opacity) ->
    #       opacity ?= 0
    #       parent.transition()
    #        .style("opacity", opacity)
    #        .duration(baseDuration)
    #        .each "end", -> blink parent, if opacity is 0 then 1 else 0

    #     pulse = (parent) ->
    #       signal = d3.select(parent).append("circle")
    #         .attr("class", "pulse")
    #         .attr("r", markerDiameter)
    #         .attr("cx", markerDiameter / 2)
    #         .attr("cy", markerDiameter / 2)
    #         .attr("fill-opacity", 0)
    #         .attr("stroke", "#00c8c8")
    #         .attr("stroke-width", 2)
    #         .transition()
    #         .attr("r", projectCircle(latlng, contribution.radius).radius)
    #         .style("opacity", 0)
    #         .ease("cubic-out")
    #         .duration(baseDuration * 6)
    #         .each "end", ->
    #           d3.select(this).remove()
    #           # pulse parent

    #     if contribution.health < Game.healthAlertThreshold
    #       blink healthProgress
    #       pulse domNode

    healthProgress = d3.select(document.createElement("div"))
    healthProgress.append("svg")
      .attr("class", "contribution-health")
      .attr("width", markerDiameter)
      .attr("height", markerDiameter)
      .append("path")
      .attr("fill", "#00c8c8")
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

      # Community Circles
      # communitiesLayer = new CommunityCirclesLayer contributions,
      #   className: "cc-map-item"
      #   fill: true
      #   fillColor: "#00c8c8"
      #   fillOpacity: communityOpacity
      #   stroke: false
      # map.addLayer communitiesLayer

      latlngs = []
      _.each contributions, (contribution) ->
        latlngs.push [contribution.geometry.coordinates[1], contribution.geometry.coordinates[0]]

      # latlngs = [contribution.geometry.coordinates[1], contribution.geometry.coordinates[0]] for contribution in data

      communitiesLayer = L.TileLayer.maskCanvas
        color: "#00c8c8"
        lineWidth: 0
        noMask: true
        opacity: communityOpacity
        radius: 200

      communitiesLayer.setData latlngs
      map.addLayer communitiesLayer
      
      # Contributions and clustering
      contributionsLayer = new L.MarkerClusterGroup
        showCoverageOnHover: false

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

  # Paper for SVG union on community rendering
  paper.setup()

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
  contributionsGeoJSON = generateRandomContributions map.getBounds(), 50

  # Prevent that map doesn't receive click events from contribution overlay
  L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]
  locate()