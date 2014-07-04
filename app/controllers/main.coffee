mainApp = angular.module "mainApp", [
  "ionic",
  "common",
  "AccountModel",
  "ContributionModel",
  "NotificationModel",
  "PhotoModel",
  "angularMoment",
  "gettext"
]

mainApp.run (amMoment, gettextCatalog) ->
  language = "de"

  if language isnt "en"
    gettextCatalog.currentLanguage = language
    gettextCatalog.debug = true
    amMoment.changeLanguage language

#-------------------------------------------------------------------------------
# Routes
#------------------------------------------------------------------------------- 
mainApp.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "login",
    url: "/login"
    templateUrl: "login.html"
    controller: "LoginCtrl"
  .state "navigation",
    url: "/navigation"
    abstract: true
    templateUrl: "navigation-menu.html"
  .state "navigation.map",
    url: "/map"
    views:
      menuContent:
        templateUrl: "map.html"
        controller: "MapCtrl"
  # .state "contribution.list",
  #   url: "/list"
  #   views:
  #     menuContent:
  #       templateUrl: "contribution-list.html"
  #       controller: "ContributionListCtrl"
  .state "navigation.contribution-detail",
    url: "/contribution-detail/:id"
    views:
      menuContent:
        templateUrl: "contribution.detail.html"
        controller: "ContributionDetailCtrl"
  .state "navigation.notifications",
    url: "/notifications"
    views:
      menuContent:
        templateUrl: "notifications.html"
        controller: "NotificationCtrl"

  $urlRouterProvider.otherwise "/login"

#-------------------------------------------------------------------------------
# MainCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MainCtrl", ($scope, $state, $ionicSideMenuDelegate, Session) ->
  $scope.toggleLeft = ->
    $ionicSideMenuDelegate.toggleLeft()

  $scope.logout = ->
    Session.logout()
    $state.go "login"

#-------------------------------------------------------------------------------
# LoginCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "LoginCtrl", ($scope, $http, $state, gettext, T, $ionicLoading, $ionicPopup, Session, Config, AccountRestangular) ->
  $scope.loginVisible = true
  $scope.login = {}
  $scope.register = {}

  $scope.login = ->
    if not $scope.login.username? or not $scope.login.password?
      $ionicPopup.alert
        title: T._ gettext "Cannot login"
        template: T._ gettext "Please enter your crededentials!"
      return

    $ionicLoading.show
      template: T._ gettext "Logging in..."

    $scope.requesting = true

    credentials = btoa "#{$scope.login.username}:#{$scope.login.password}"
    $http
      url: "#{Config.API_ENDPOINT}/accounts/users/"
      method: "GET"
      headers:
        "Authorization": "Basic #{credentials}"
    .success (data) ->
      Session.login data.results[0].username, data.results[0].id
      $scope.reset()
      $ionicLoading.hide()
      $state.go "navigation.map", {}, { reload: true }
    .error (data) ->
      $ionicPopup.alert
        title: T._ gettext "An error occured"
        template: data.detail
      $scope.requesting = false
      $ionicLoading.hide()

  $scope.register = ->
    if not $scope.register.username or not $scope.register.email or not $scope.register.password
      $ionicPopup.alert 
        title: T._ gettext "You are not done yet"
        template: T._ gettext "Please enter all details!"
      return

    if not $scope.register.username.match Config.REGEX_USERNAME
      $ionicPopup.alert 
        title: T._ gettext "Your username is invalid"
        template: T._ gettext "It may contain letters, numbers, the characters '-', '_' and '.' but no special characters."
      return

    $ionicLoading.show
      template: T._ gettext "Registering account..."

    $scope.requesting = true

    AccountRestangular.all("register").post
      username: $scope.register.username
      email: $scope.register.email
      password: $scope.register.password
    .then (response) ->
      Session.login response.username, response.id
      $scope.reset()
      $ionicLoading.hide()
      $state.go "navigation.map", {}, { reload: true }
    , (response) ->
      $scope.requesting = false
      $ionicLoading.hide()
      title = T._ gettext "Sorry, an error occured"
      msg = T._ gettext "Please try again later."

      if response.hasOwnProperty "data"
        if response.data.hasOwnProperty "password"
          title = T._ gettext "Error with password"
          msg = response.data.password

        if response.data.hasOwnProperty "email"
          title = T._ gettext "Error with email"
          msg = response.data.email

        if response.data.hasOwnProperty "username"
          title = T._ gettext "Error with username"
          msg = response.data.username

      $ionicPopup.alert
        title: title
        template: msg

  $scope.switchView = ->
    if $scope.loginVisible
      $scope.loginVisible = false
    else
      $scope.loginVisible = true

  $scope.reset = ->
    $scope.loginVisible = true
    $scope.login.username = null
    $scope.login.password = null
    $scope.register.username = null
    $scope.register.email = null
    $scope.register.password = null
    $scope.requesting = false

#-------------------------------------------------------------------------------
# Map
#------------------------------------------------------------------------------- 
mainApp.controller "MapCtrl", ($scope, $http, $state, Game, Log, Config, Color, UI, Util, ContributionRestangular, PhotoRestangular) ->

  $scope.message_id = "mapIndexCtrl"

  markerDiameter = 40
  mapPreviewHeight = 80
  communityOpacity = 0.4
  communityColor = Color.ccLight
  contributionColor = Color.ccMain
  baseAnimationDuration = 500
  animationDuration = 0.3
  pulseDuration = baseAnimationDuration * 6
  contributionDetailVisible = false

  currentPositionInterval = null
  currentPositionIntervalTime = 5000

  # Detect double-clicks for contribution marker
  contributionClickCount = 0

  contributions = null

  # Map Layer
  communitiesLayer = null
  contributionsLayer = null

  contributionMarkers = []
  selectedContributionMarker = null
  currentPositionMarker = null

  # Map controls
  locateControl = null

  map = new L.Map "map",
    center: Util.lastKnownPosition()
    zoom: 14
    zoomControl: false

  $scope.loading = false
  $scope.contributionSelected = false;
  $scope.contribution = {}

  $scope.baseUrl = Config.API_ENDPOINT

  #-----------------------------------------------------------------------------
  # CUSTOM MAP CONTROLS
  #-----------------------------------------------------------------------------
  LocateControl = L.Control.extend
    options:
      position: "bottomright"

    onAdd: (map) ->
      this._container = L.DomUtil.create "button", "button button-positive icon ion-navigate"
      L.DomEvent.addListener this._container, "click", (e) ->
        L.DomEvent.stopPropagation e
        locate()

      return this._container
      
  #-----------------------------------------------------------------------------
  # MAP EVENTS
  #-----------------------------------------------------------------------------
  map.on "click", (e) ->
    if contributionDetailVisible
      $scope.hideContributionDetail()
      $scope.$apply()

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
    # Log.i "Location found: #{e.latlng.lat}, #{e.latlng.lng}"
    $scope.$apply -> $scope.loading = false
    loadContributions()
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

  map.on "viewreset", (e) ->
    loadContributions()

  map.on "moveend", (e) ->
    loadContributions()

  map.on "error", (e) ->
    $scope.$apply -> $scope.loading = false
    Log.e "Leaflet error: #{e.message}"

  contributionMarkerClicked = (e) ->
    $scope.$apply -> $scope.imageSrc = null
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
          map.removeLayer currentPositionMarker
          map.removeLayer communitiesLayer
          _.each contributionMarkers, (marker) ->
            if marker is e.target
              selectedContributionMarker = e.target
            else
              contributionsLayer.removeLayer marker

          id = parseInt e.target.feature.id
          $scope.showContributionDetail id
        else
          $scope.hideContributionDetail()
          $scope.$apply()
      contributionClickCount = 0
    , 200

  onVisibilityChange = ->
    loadContributions() if not document.hidden

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
      setView: true
      enableHighAccuracy: true
      # watch: true

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
        html: "#{healthProgress.node().innerHTML}<div class=\"contribution-icon contribution-icon-#{Util.convertContributionType feature.properties.type}\"></div>"
    return svgMarker

  # Helper function for loading map data with spinner
  loadContributions =  ->
    return if $scope.contributionSelected

    $scope.loading = true

    mapBounds = map.getBounds()
    # contributions = ContributionRestangular.all("contribution").getList
    #   sw_boundingbox_coordinate_lat: mapBounds.getSouthWest().lat
    #   sw_boundingbox_coordinate_long: mapBounds.getSouthWest().lng
    #   ne_boundingbox_coordinate_lat: mapBounds.getNorthEast().lat
    #   ne_boundingbox_coordinate_long: mapBounds.getNorthEast().lng
    #   convert: "geojson"
    # .then (data) ->
    $http
      url: "#{Config.API_ENDPOINT}/contrib/contribution/"
      method: "GET"
      params:
        sw_boundingbox_coordinate_lat: mapBounds.getSouthWest().lat
        sw_boundingbox_coordinate_long: mapBounds.getSouthWest().lng
        ne_boundingbox_coordinate_lat: mapBounds.getNorthEast().lat
        ne_boundingbox_coordinate_long: mapBounds.getNorthEast().lng
        convert: "geojson"
    .success (data) ->
      # map.removeLayer communitiesLayer unless communitiesLayer is null
      map.removeLayer contributionsLayer unless contributionsLayer is null

      contributionMarkers = []
      contributions = data.features
      
      # Contributions and clustering
      contributionsLayer = new L.MarkerClusterGroup
        iconCreateFunction: (cluster) ->
          return new L.DivIcon
            html: "<div class=\"contribution-marker-cluster\"><span>#{cluster.getChildCount()}</span></div>"
        maxClusterRadius: markerDiameter + 5
        removeOutsideVisibleBounds: true
        showCoverageOnHover: false
        spiderfyDistanceMultiplier: 1.6
        spiderfyOnMaxZoom: true
        zoomToBoundsOnClick: true

      geoJsonLayer = L.geoJson data,
        onEachFeature: (feature, layer) ->
          layer.on "click", contributionMarkerClicked
        pointToLayer: (feature, latlng) ->
          contributionMarker = createContributionMarker feature, latlng
          contributionMarkers.push contributionMarker
          return contributionMarker

      contributionsLayer.addLayer geoJsonLayer
      
      map.addLayer contributionsLayer

      $scope.loading = false
    .error ->
      Log.e "Could not load contributions"
      $scope.loading = false

    $http
      url: "#{Config.API_ENDPOINT}/contrib/community/"
      method: "GET"
      params:
        sw_boundingbox_coordinate_lat: mapBounds.getSouthWest().lat
        sw_boundingbox_coordinate_long: mapBounds.getSouthWest().lng
        ne_boundingbox_coordinate_lat: mapBounds.getNorthEast().lat
        ne_boundingbox_coordinate_long: mapBounds.getNorthEast().lng
    .success (data) ->
      # console.log data
      map.removeLayer communitiesLayer unless communitiesLayer is null
      communitiesLayer = L.geoJson data,
        style: 
          clickable: false
          stroke: false
          fillColor: communityColor
          fillOpacity: communityOpacity
      map.addLayer communitiesLayer
      $scope.loading = false
    .error ->
      Log.e "Could not load communities"
      $scope.loading = false

  updateCurrentPositionMarker = (latlng) ->
    # Clean up
    map.removeLayer currentPositionMarker unless currentPositionMarker is null

    currentPositionMarker = Util.createPositionMarker latlng #, Game.initialRadius

    map.addLayer currentPositionMarker, true

  #-----------------------------------------------------------------------------
  # UI EVENTS
  #-----------------------------------------------------------------------------
  $scope.newContribution = ->
    $state.go "contribution.new"

  $scope.locate = ->
    locate()

  $scope.openContribution = ->
    $state.go "navigation.contribution-detail", id: $scope.contribution.id

  $scope.showContributionDetail = (id) ->
    $scope.contributionSelected = true
    $scope.contribution = _.filter(contributions, (e) -> return e.id is id)[0]
    $scope.contribution.properties.area = Util.formatAreaSqKm $scope.contribution.properties.radius * $scope.contribution.properties.radius * Math.PI
    if $scope.contribution.properties.photos.length > 0
      $scope.imageSrc = "#{Config.API_ENDPOINT}/download/?photo_id=#{$scope.contribution.properties.photos[0]}&convert=square_200"
    else
      $scope.imageSrc = null

    # Pan map to contribution and offset it on top
    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    offset = [0, -(map.getSize().y / 2 - mapPreviewHeight / 2)]
    x = map.latLngToContainerPoint(latlng).x - offset[0]
    y = map.latLngToContainerPoint(latlng).y - offset[1]
    point = map.containerPointToLatLng [x, y]
    map.setView point
    
    Util.disableMapInteraction map

    # Wait for the animation
    setTimeout ( -> contributionDetailVisible = true), animationDuration

    $scope.$apply()

  $scope.hideContributionDetail = ->
    contributionDetailVisible = false
    $scope.contributionSelected = false

    latlng = new L.LatLng $scope.contribution.geometry.coordinates[1], $scope.contribution.geometry.coordinates[0]
    map.setView latlng
    
    Util.enableMapInteraction map

    # Show contributions
    contributionsLayer.removeLayer selectedContributionMarker
    map.addLayer communitiesLayer
    _.each contributionMarkers, (marker) ->
      contributionsLayer.addLayer marker
    map.addLayer currentPositionMarker

    map.addControl locateControl
    
    selectedContributionMarker = null

  #-----------------------------------------------------------------------------
  # INITIALIZE
  #-----------------------------------------------------------------------------
  Util.createTileLayer().addTo map

  locateControl = new LocateControl()

  map.addControl locateControl

  currentPositionInterval = setInterval ->
    updateCurrentPositionMarker Util.lastKnownPosition()
  , currentPositionIntervalTime   
  
  # Prevents that WebView is dragged
  document.ontouchmove = (e) -> e.preventDefault()
  document.addEventListener "visibilitychange", onVisibilityChange, false

  # Prevent that map doesn't receive click events from contribution overlay
  L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]

  # UI.listen $scope 

  # if not Util.loggedIn()
  #   Util.logout()

  locate()

#-------------------------------------------------------------------------------
# ContributionListCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "ContributionListCtrl", ($scope) ->
  return

#-------------------------------------------------------------------------------
# NotificationCtrl
#-------------------------------------------------------------------------------
mainApp.controller "NotificationCtrl", ($scope, gettext, T, $ionicLoading, $ionicListDelegate, Session, Log, NotificationRestangular) ->
  $scope.notifications = []

  $scope.loadNotifications = ->
    $ionicLoading.show
      template: T._ gettext "Loading notifications..."
    NotificationRestangular.all("notifications").getList
      user: Session.userId()
    .then (data) ->
      $scope.notifications = data
    .finally ->
      $ionicLoading.hide()

  $scope.read = (notification) ->
    req = NotificationRestangular.one "notification", notification.id
    req.user = Session.userId()
    req.is_read = !notification.is_read
    req.put().then (data) ->
      $scope.loadNotifications()
    , (data) ->
      Log.e data
    .finally ->
      $ionicListDelegate.closeOptionButtons()

  $scope.dismiss = (notification) ->
    NotificationRestangular.one("notification", notification.id).remove().then (data) ->
      $scope.loadNotifications()
    , (data) ->
      Log.e data
    .finally ->
      $ionicListDelegate.closeOptionButtons()

  $scope.openContribution = (contribution) ->
    return

  # Init
  $scope.loadNotifications()

#-------------------------------------------------------------------------------
# ContributionDetailCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "ContributionDetailCtrl", ($scope, $stateParams, $filter, $location, $anchorScroll, gettext, T, $ionicLoading, $ionicPopup, Config, Log, UI, ContributionRestangular) ->
  $scope.message_id = "showContributionController"
  $scope.contribution = {}
  $scope.comments = []
  $scope.baseUrl = Config.API_ENDPOINT
  $scope.imageWidth = screen.width
  $scope.imageHeight = $scope.imageWidth

  scrollBottom = false

  $scope.loadContribution = (id) ->
    $scope.contribution.id = id
    $ionicLoading.show template: T._ gettext "Loading contribution..."
    $scope.imageSrc = null

    ContributionRestangular.all("contribution").getList(id: id).then (data) ->
      $scope.contribution = data[0]
      $scope.imageSrc = "#{Config.API_ENDPOINT}/download/?photo_id=#{$scope.contribution.photos[0]}&convert=square_640" if $scope.contribution.photos[0]
    .finally ->
      $ionicLoading.hide()

      $scope.loadComments $scope.contribution.id

  $scope.loadComments = (id) ->
    $ionicLoading.show template: T._ gettext "Loading comments..."
    ContributionRestangular.all("comment").getList(contribution: id).then (data) ->
      $scope.comments = data
      # $scope.$apply()

      if scrollBottom
        scrollBottom = false
        $location.hash "bottom"
        $anchorScroll()
        # $scope.$apply()
    , (response) ->
      Log.e "Couldn't load comments (#{response.data.detail})"
      $scope.$apply()
    .finally ->
      $ionicLoading.hide()

  $scope.addComment = ->
    lblComments = T._ gettext "Comments"

    prompt = $ionicPopup.show
      template: "<textarea placeholder=#{lblComments} ng-model=\"comment\"></textarea>"
      title: T._ gettext "Please enter a comment"
      scope: $scope
      buttons: [
        text: T._ gettext "Cancel"
      ,
        text: T._ gettext "Send",
        type: 'button-positive',
        onTap: (e) ->
          if !$scope.comment
            # Don't allow the user to close unless comment is entered
            e.preventDefault()
          else
            return $scope.comment
      ]

    prompt.then (res) ->
      $scope.sendComment()

  $scope.sendComment = ->
    $ionicLoading.show template: T._ "Sending comment..."
    ContributionRestangular.all("comment").post
      author: Util.userId()
      content: $scope.comment
      contribution: $scope.contribution.id
    .then (response) ->
      $scope.comment = null
      scrollBottom = true
      $scope.loadContribution $scope.contribution.id
    , (response) ->
      Log.e "Couldn't send comment (#{JSON.stringify response.data})"
      $ionicPopup.alert
        title: T._ gettext "Couldn't upload comment"
        template: T._ gettext "Please try again later"
    .finally ->
      $ionicLoading.hide()

  $scope.voteContribution = ->
    if not $scope.hasVotedForContribution()
      ContributionRestangular.all("votecontribution").post
        contribution: $scope.contribution.id
        creator: Util.userId()
      .then (response) ->
        $scope.loadContribution $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      $ionicPopup.alert
        title: T._ gettext "You have already voted"
        template: T._ gettext "...and removing votes isn't implemented yet ;)"

  $scope.hasVotedForContribution = ->
    return _.contains $scope.contribution.votes, Util.userName()

  $scope.voteComment = (comment) ->
    if not $scope.hasVotedForComment comment
      ContributionRestangular.all("votecomment").post
        comment: comment.id
        creator: Util.userId()
      .then (response) ->
        $scope.loadComments $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      $ionicPopup.alert
        title: T._ gettext "You have already voted"
        template: T._ gettext "...and removing votes isn't implemented yet ;)"

  $scope.hasVotedForComment = (comment) ->
    return _.contains comment.votes, Util.userName()

  $scope.votePollOption = (poll_option) ->
    if not $scope.hasVotedForPollOption poll_option
      ContributionRestangular.all("votepolloption").post
        poll_option: poll_option.id
        creator: Util.userId()
      .then (response) ->
        $scope.loadContribution $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
      , (response) ->
        Log.e "Couldn't vote poll option #{JSON.stringify response}"
        $ionicPopup.alert
          title: T._ gettext "You have already voted for this poll!"
          template: T._ gettext "Please remove your previous vote first"
    else
      $ionicPopup.alert
        title: T._ gettext "You have already voted for this poll!"
        template: T._ gettext "...and removing votes isn't implemented yet ;)"

  $scope.hasVotedForPollOption = (poll_option) ->
    return _.contains poll_option.votes, Util.userName()

  # Init
  # UI.listen $scope
  $scope.loadContribution $stateParams.id
