mainApp = angular.module "mainApp", [
  "ionic",
  "common",
  "bPart",
  "templates",
  "AccountModel",
  "ContributionModel",
  "NotificationModel",
  "PhotoModel",
  "PoiModel",
  "angularMoment",
  "gettext",
  "ngCordova"
]

#-------------------------------------------------------------------------------
# Routes
#------------------------------------------------------------------------------- 
mainApp.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "app",
    url: "/app"
    abstract: true
    templateUrl: "navigation.html"
  .state "app.map",
    url: "/map"
    views:
      mainContent:
        templateUrl: "map.html"
        controller: "MapCtrl"
  .state "app.contribution-new",
    url: "/contribution-new"
    views:
      mainContent:
        templateUrl: "contribution.new.html"
        controller: "ContributionNewCtrl"
  .state "app.contribution-detail",
    url: "/contribution-detail/:id"
    views:
      mainContent:
        templateUrl: "contribution.detail.html"
        controller: "ContributionDetailCtrl"
  .state "app.contribution-list",
    url: "/contribution-list"
    views:
      mainContent:
        templateUrl: "contribution.list.html"
        controller: "ContributionListCtrl"
  .state "app.notifications",
    url: "/notifications"
    views:
      mainContent:
        templateUrl: "notifications.html"
        controller: "NotificationCtrl"
  .state "app.mood",
    url: "/mood"
    views:
      mainContent:
        templateUrl: "mood.html"
        controller: "MoodCtrl"
  .state "app.poi",
    url: "/poi"
    views:
      mainContent:
        templateUrl: "poi.html"
        controller: "PoiCtrl"
  .state "app.settings",
    url: "/settings"
    views:
      mainContent:
        templateUrl: "settings.html"
        controller: "SettingsCtrl"
  .state "app.profile",
    url: "/profile/:username"
    views:
      mainContent:
        templateUrl: "profile.html"
        controller: "ProfileCtrl"
  .state "app.imprint",
    url: "/imprint"
    views:
      mainContent:
        templateUrl: "imprint.html"
        # controller: "ImprintCtrl"
  .state "app.mission-list",
    url: "/mission-list"
    views:
      mainContent:
        templateUrl: "mission.list.html"
        controller: "MissionListCtrl"
  .state "app.mission-detail",
    url: "/mission-detail/:id"
    views:
      mainContent:
        templateUrl: "mission.detail.html"
        controller: "MissionDetailCtrl"
  .state "app.mission-select",
    url: "/mission-select"
    views:
      mainContent:
        templateUrl: "mission.select.html"
        controller: "MissionSelectCtrl"

  $urlRouterProvider.otherwise "/app/map"

#-------------------------------------------------------------------------------
# Factory (shared models)
#-------------------------------------------------------------------------------
mainApp.factory "contributionModel", ->
  title: null
  type: null
  description: null
  mood: null
  accuracy: null
  latlng: null
  poi: null
  mission: null
  poll_options: []
  photo_src: null
  photo_file: null

  reset: ->
    @title = null
    @type = null
    @description = null
    @mood = null
    @accuracy = null
    @latlng = null
    @poi = null
    @mission = null
    @poll_options = []
    @photo_src = null
    @photo_file = null

  isDirty: ->
    return @title isnt null or
    @type isnt null or
    @description isnt null or
    @mood isnt null or
    @poi isnt null or
    @mission isnt null or
    @poll_options.length > 0 or
    @photo_src isnt null

#-------------------------------------------------------------------------------
# Init
#-------------------------------------------------------------------------------
mainApp.run ($rootScope, $templateCache, $ionicPlatform, T, gettext, Log, Config, amMoment, gettextCatalog) ->
  Log.i "Running mainApp..."

  $rootScope.mapLocateInterval = null

  # $ionicPlatform.ready ->
  #   # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
  #   # for form inputs)
  #   if window.cordova and window.cordova.plugins.Keyboard 
  #     cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

  #   if window.StatusBar
  #     StatusBar.overlaysWebView true
  #     StatusBar.styleLightContent()

  # Set language
  $rootScope.language = localStorage.getItem("language") or "de"
  localStorage.setItem "language", $rootScope.language

  # $rootScope.checkLanguage = -> 
  #   navigator.globalization.getPreferredLanguage (language) ->  
  #     console.log language.value
  #   ,
  #   ->
  #     console.log "no languate"
  # $rootScope.checkLanguage()

  if $rootScope.language isnt "en"
    gettextCatalog.currentLanguage = $rootScope.language
    amMoment.changeLanguage $rootScope.language

  $rootScope.getMoods = ->
    return [
      "code": "happy"
      "name": T._ gettext "happy"
    ,
      "code": "unhappy"
      "name": T._ gettext "unhappy"
    ,
      "code": "crying"
      "name": T._ gettext "sad"
    ,
      "code": "angry"
      "name": T._ gettext "angry"
    ,
      "code": "overhappy"
      "name": T._ gettext "overhappy"
    ,
      "code": "shocked"
      "name": T._ gettext "shocked"
    ,
      "code": "confused"
      "name": T._ gettext "confused"
    ,
      "code": "inlove"
      "name": T._ gettext "in love"
    ,
      "code": "intelligent"
      "name": T._ gettext "smart"
    ,
      "code": "blinking"
      "name": T._ gettext "ironic"
    ,
      "code": "silent"
      "name": T._ gettext "silent"
    ,
      "code": "king"
      "name": T._ gettext "royal"
    ,
      "code": "thief"
      "name": T._ gettext "sneaky"
    ,
      "code": "toothy"
      "name": T._ gettext "childish"
    ,
      "code": "sleepy"
      "name": T._ gettext "tired"
    ,
      "code": "sealed"
      "name": T._ gettext "sealed"
    ]

  # Moods
  $rootScope.moods = $rootScope.getMoods()

  # Save last visited view
  $rootScope.$on "$stateChangeSuccess", (event, toState, toParams, fromState, fromParams) ->
    localStorage.setItem "last_visited", toState.name if toState.name in ["app.map", "app.contribution-list", "app.notifications"]
    $rootScope.previousState = fromState

    if fromState.name == "app.map" and $rootScope.mapLocateInterval?
      clearInterval $rootScope.mapLocateInterval
      $rootScope.mapLocateInterval = null

#-------------------------------------------------------------------------------
# MainCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MainCtrl", ($scope, $state, $http, gettext, T, $ionicLoading, $ionicPopup, $ionicModal, $ionicSideMenuDelegate, Account, Session, Config, Color, NotificationRestangular) ->
  $scope.version = Config.VERSION
  $scope.supportEmail = Config.SUPPORT_EMAIL
  $scope.username = Session.userName()

  $scope.loginVisible = true
  $scope.login = {}
  $scope.register = {}

  $scope.setNotificationUnreadCount = ->
    NotificationRestangular.setErrorInterceptor (response, deferred, responseHandler) ->
      if response.status is 401
        $scope.logout()
        return true

    NotificationRestangular.all("notifications").getList().then (data) ->
      unread = _.where data, is_read: false
      $scope.notifications_unread_count = unread.length

  $scope.login = ->
    if not $scope.login.username? or not $scope.login.password?
      $ionicPopup.alert
        title: T._ gettext "Cannot login"
        template: T._ gettext "Please enter your credentials"
      return

    $ionicLoading.show
      template: T._ gettext "Logging in..."

    $scope.requesting = true
    Account.login($scope.login.username, $scope.login.password).then (data) ->
      $scope.username = Session.userName()
      $state.go $state.current, {}, reload: true
      $ionicLoading.hide()
      $scope.reset()
      $scope.modal.hide()
    , (data) ->
      $ionicLoading.hide()
      $ionicPopup.alert
        title: T._ gettext "An error occured"
        template: T._ gettext "Invalid password or username"
    .finally ->
      $scope.requesting = false

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

    Account.register
      username: $scope.register.username
      email: $scope.register.email
      password: $scope.register.password
    .then (response) ->
      $ionicLoading.hide()

      # Login/obtain token
      $ionicLoading.show
        template: T._ gettext "Logging in..."

      $scope.requesting = true
      Account.login($scope.register.username, $scope.register.password).then (data) ->
        $scope.username = Session.userName()
        $state.go $state.current, {}, reload: true
        $ionicLoading.hide()
        $scope.reset()
        $scope.modal.hide()
      , (data) ->
        $ionicLoading.hide()
        $ionicPopup.alert
          title: T._ gettext "An error occured"
          template: data
      .finally ->
        $scope.requesting = false
        $scope.reset()

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

  $scope.logout = ->
    Account.logout() if Session.loggedIn()
    $ionicModal.fromTemplateUrl "login.html",
      scope: $scope,
      animation: "slide-in-up"
      backdropClickToClose: false
      hardwareBackButtonClose: false
    .then (modal) ->
      $scope.modal = modal
      $scope.modal.show()
      $ionicSideMenuDelegate.toggleLeft() if $ionicSideMenuDelegate.isOpenLeft()
      steroids.view.setBackgroundColor Color.ccMain

  $scope.toggleNavigationMenu = ->
    $ionicSideMenuDelegate.toggleLeft()
    $scope.setNotificationUnreadCount()

  $scope.$on "modal.hidden", ->
    steroids.view.setBackgroundColor "#ffffff"

  # Init
  $scope.logout() if not Session.loggedIn()
  $scope.setNotificationUnreadCount()

#-------------------------------------------------------------------------------
# Map
#------------------------------------------------------------------------------- 
mainApp.controller "MapCtrl", ($scope, $rootScope, $http, $state, $ionicPlatform, Game, Log, Config, Color, Util, UI, Session, ContributionRestangular, PhotoRestangular, Backend) ->

  markerDiameter = 40
  mapPreviewHeight = 80
  communityOpacity = 0.5
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

  $scope.contributionSelected = false;
  $scope.contribution = {}

  $scope.baseUrl = Config.API_ENDPOINT

  #-----------------------------------------------------------------------------
  # CUSTOM MAP CONTROLS
  #-----------------------------------------------------------------------------
  LocateControl = L.Control.extend
    options:
      position: "topleft"

    onAdd: (map) ->
      this._container = L.DomUtil.create "button", "button button-positive icon ion-pinpoint"
      L.DomEvent.addListener this._container, "click", (e) ->
        L.DomEvent.stopPropagation e
        locate true

      return this._container
      
  #-----------------------------------------------------------------------------
  # MAP
  #-----------------------------------------------------------------------------
  map = new L.Map "map",
    attributionControl: false
    center: Util.lastKnownPosition()
    zoom: 14
    zoomControl: false

  map.on "click", (e) ->
    if contributionDetailVisible
      $scope.hideContributionDetail()
      $scope.$apply()

  map.on "locationfound", (e) ->
    localStorage.setItem "position.coords.latitude", e.latitude
    localStorage.setItem "position.coords.longitude", e.longitude
    localStorage.setItem "position.coords.accuracy", e.accuracy
    localStorage.setItem "position.timestamp", e.timestamp
    # loadContributions()
    updateCurrentPositionMarker e.latlng

  map.on "locationerror", (e) ->
    Log.w "Could not determine position (code=#{e.code}). #{e.message}"

  map.on "viewreset", (e) ->
    # Log.d "viewreset"
    Util.lastKnownMapBounds map.getBounds()
    loadContributions()

  map.on "moveend", (e) ->
    # Log.d "moveend"
    Util.lastKnownMapBounds map.getBounds()
    loadContributions()

  map.on "error", (e) ->
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

  #-----------------------------------------------------------------------------
  # INTERNAL FUNCTIONS
  #-----------------------------------------------------------------------------
  locate =  (setView) ->
    map.locate
      setView: setView
      enableHighAccuracy: ionic.Platform.isIOS()

  loadContributions =  ->
    return if $scope.contributionSelected

    mapBounds = map.getBounds()
    Backend.all("contrib").customGET "contribution",
      sw_boundingbox_coordinate_lat: mapBounds.getSouthWest().lat
      sw_boundingbox_coordinate_long: mapBounds.getSouthWest().lng
      ne_boundingbox_coordinate_lat: mapBounds.getNorthEast().lat
      ne_boundingbox_coordinate_long: mapBounds.getNorthEast().lng
      convert: "geojson"
    .then (data) ->
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
          contributionMarker = Util.createContributionMarker latlng, feature.properties, markerDiameter
          contributionMarkers.push contributionMarker
          return contributionMarker

      contributionsLayer.addLayer geoJsonLayer
      
      map.addLayer contributionsLayer
    , (error) ->
      Log.e "Could not load contributions"

    Backend.all("contrib").customGET "community",
      sw_boundingbox_coordinate_lat: mapBounds.getSouthWest().lat
      sw_boundingbox_coordinate_long: mapBounds.getSouthWest().lng
      ne_boundingbox_coordinate_lat: mapBounds.getNorthEast().lat
      ne_boundingbox_coordinate_long: mapBounds.getNorthEast().lng
    .then (data) ->
      map.removeLayer communitiesLayer unless communitiesLayer is null
      communitiesLayer = L.geoJson data,
        style: (feature) ->
          clickable: false
          stroke: false
          fillColor: if feature.properties.is_home_community then Color.ccDark else if feature.properties.contributions_count > 1 then communityColor else Color.ccLighter
          fillOpacity: if feature.properties.contributions_count > 1 then communityOpacity else 0.2
      map.addLayer communitiesLayer
    , (error) ->
      console.log error
      Log.e "Could not load communities"

    Backend.all("home").customGET().then (data) ->
      map.removeLayer @homeLayer if typeof(@homeLayer) isnt "undefined"
      @homeLayer = L.geoJson data,
        pointToLayer: (feature, latlng) ->
          return Util.createHomeMarker latlng
      map.addLayer @homeLayer
    , (error) ->
      Log.w "Cannot place home community: #{error.data.detail}"

  updateCurrentPositionMarker = (latlng) ->
    if not currentPositionMarker?
      currentPositionMarker = Util.createPositionMarker latlng
      currentPositionMarker.addTo map
    currentPositionMarker.setLatLng latlng

  #-----------------------------------------------------------------------------
  # UI EVENTS
  #-----------------------------------------------------------------------------
  $scope.newContribution = ->
    $state.go "app.contribution-new"

  # $scope.locate = ->
  #   locate()

  $scope.openContribution = ->
    $state.go "app.contribution-detail", id: $scope.contribution.id

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

    map.addControl locateControl
    
    selectedContributionMarker = null

  #-----------------------------------------------------------------------------
  # INITIALIZE
  #-----------------------------------------------------------------------------
  Util.createTileLayer().addTo map
  locateControl = new LocateControl()
  map.addControl locateControl
  if Util.lastKnownMapBounds()
    map.fitBounds Util.lastKnownMapBounds()
    locate false
  else
    locate true

  # currentPositionInterval = setInterval ->
  #   updateCurrentPositionMarker Util.lastKnownPosition()
  # , currentPositionIntervalTime   
  
  # Prevents that WebView is dragged
  # document.ontouchmove = (e) -> e.preventDefault()
  # document.addEventListener "visibilitychange", onVisibilityChange, false

  # Prevent that map doesn't receive click events from contribution overlay
  # L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]

  # Fetch location in background
  if not $rootScope.mapLocateInterval?
    $rootScope.mapLocateInterval = setInterval ->
      locate false
    , 5000

  loadContributions()

  # Set height of map (for some reason the height of 100% doesn't work)
  # $ionicPlatform.ready ->
  #   document.getElementById("map").style.height = document.getElementsByClassName("scroll-content")[0].offsetHeight

#-------------------------------------------------------------------------------
# NotificationCtrl
#-------------------------------------------------------------------------------
mainApp.controller "NotificationCtrl", ($scope, gettext, $state, T, $ionicLoading, $ionicListDelegate, Session, Log, NotificationRestangular) ->
  # $scope.notifications = []

  $scope.loadNotifications = ->
    $ionicLoading.show
      template: T._ gettext "Loading notifications..."
    NotificationRestangular.all("notifications").getList().then (data) ->
      $scope.notifications = data
    , (data) ->
      Log.e "Couldn't load notifications: #{JSON.stringify data}"
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  $scope.read = (notification, isRead) ->
    req = NotificationRestangular.one "notification", notification.id
    req.is_read = isRead
    req.put().then (data) ->
      $scope.loadNotifications()
    , (data) ->
      Log.e "Couldn't set read status: #{JSON.stringify data}"
    .finally ->
      $ionicListDelegate.closeOptionButtons()

  $scope.dismiss = (notification) ->
    NotificationRestangular.one("notification", notification.id).remove().then (data) ->
      $scope.loadNotifications()
    , (data) ->
      Log.e "Couldn't delete notification: #{JSON.stringify data}"
    .finally ->
      $ionicListDelegate.closeOptionButtons()

  $scope.openContribution = (notification) ->
    $scope.read notification, true
    $state.go "app.contribution-detail", id: notification.ref_contribution

  # Init
  $scope.loadNotifications()

#-------------------------------------------------------------------------------
# ContributionDetailCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "ContributionDetailCtrl", ($scope, $stateParams, $filter, $ionicScrollDelegate, gettext, T, $ionicLoading, $ionicPopup, Config, Log, Util, UI, Session, ContributionRestangular) ->
  $scope.contribution = {}
  $scope.comments = []
  $scope.baseUrl = Config.API_ENDPOINT
  $scope.imageWidth = window.innerWidth
  $scope.imageHeight = $scope.imageWidth

  scrollBottom = false
  contributionMarker = null

  map = new L.Map "contribution-map",
    attributionControl: false
    center: Util.lastKnownPosition()
    zoom: 14
    zoomControl: false

  $scope.loadContribution = (id) ->
    $scope.contribution.id = id
    $ionicLoading.show template: T._ gettext "Loading contribution..."
    $scope.imageSrc = null

    ContributionRestangular.all("contribution").getList(id: id).then (data) ->
      $scope.contribution = data[0]
      $scope.imageSrc = "#{Config.API_ENDPOINT}/download/?photo_id=#{$scope.contribution.photos[0]}&convert=square_640" if $scope.contribution.photos[0]
      latlng = Util.pointToLatLng $scope.contribution.point
      map.setView latlng, map.getMaxZoom()
      map.removeLayer contributionMarker if contributionMarker
      contributionMarker = Util.createContributionMarker latlng, $scope.contribution
      contributionMarker.addTo map
    .finally ->
      $ionicLoading.hide()
      $scope.loadComments $scope.contribution.id

  $scope.loadComments = (id) ->
    $ionicLoading.show template: T._ gettext "Loading comments..."
    ContributionRestangular.all("comment").getList(contribution: id).then (data) ->
      $scope.comments = data

      if scrollBottom
        scrollBottom = false
        $ionicScrollDelegate.scrollBottom true
    , (response) ->
      Log.e "Couldn't load comments (#{response.data.detail})"
      $scope.$apply()
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  $scope.addComment = ->
    $scope.data = {}
    lblComment = T._ gettext "Comment"

    prompt = $ionicPopup.show
      template: "<textarea placeholder=\"#{lblComment}\" ng-model=\"data.comment\" rows=\"5\"></textarea>"
      title: T._ gettext "Please enter a comment"
      scope: $scope
      buttons: [
        text: T._ gettext "Cancel"
      ,
        text: T._ gettext "Send"
        type: "button-positive"
        onTap: (e) ->
          if not $scope.data.comment
            # Don't allow the user to close unless comment is entered
            e.preventDefault()
          else
            return $scope.data.comment
      ]

    prompt.then (res) ->
      $scope.sendComment res if res

  $scope.sendComment = (comment) ->
    $ionicLoading.show template: T._ "Sending comment..."
    ContributionRestangular.all("comment").post
      content: comment
      contribution: $scope.contribution.id
    .then (response) ->
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
      .then (response) ->
        $scope.loadContribution $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      ContributionRestangular.one("votecontribution", $scope.contribution.id).remove().then ->
        $scope.loadContribution $scope.contribution.id

  $scope.hasVotedForContribution = ->
    return _.contains $scope.contribution.votes, Session.userName()

  $scope.voteComment = (comment) ->
    if not $scope.hasVotedForComment comment
      ContributionRestangular.all("votecomment").post
        comment: comment.id
      .then (response) ->
        $scope.loadComments $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      ContributionRestangular.one("votecomment", comment.id).remove().then -> 
        $scope.loadComments $scope.contribution.id

  $scope.hasVotedForComment = (comment) ->
    return _.contains comment.votes, Session.userName()

  $scope.votePollOption = (poll_option) ->
    if not $scope.hasVotedForPollOption poll_option
      ContributionRestangular.all("votepolloption").post
        poll_option: poll_option.id
      .then (response) ->
        $scope.loadContribution $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
      , (response) ->
        Log.e "Couldn't vote poll option #{JSON.stringify response}"
        $ionicPopup.alert
          title: T._ gettext "You have already voted for this poll!"
          template: T._ gettext "Please remove your previous vote first"
    else
      ContributionRestangular.one("votepolloption", poll_option.id).remove().then ->
        $scope.loadContribution $scope.contribution.id

  $scope.hasVotedForPollOption = (poll_option) ->
    return _.contains poll_option.votes, Session.userName()

  # Init
  # UI.listen $scope
  Util.createTileLayer().addTo map
  Util.disableMapInteraction map
  $scope.loadContribution $stateParams.id

#-------------------------------------------------------------------------------
# ContributionNewCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ContributionNewCtrl", ($scope, $rootScope, $http, $state, $cordovaGeolocation, gettext, T, contributionModel, $ionicLoading, $ionicPopup, $ionicActionSheet, $ionicNavBarDelegate, Util, Log, Config, Session, ContributionRestangular) ->

  currentPositionMarker = null
  $scope.hasError = false
  $scope.isAndroid = ionic.Platform.isAndroid()

  #-----------------------------------------------------------------------------
  # CONTRIBUTION PROPERTIES
  #-----------------------------------------------------------------------------
  $scope.contribution = contributionModel

  if $scope.contribution.photo_src?
    $scope.bgImageStyle =
      "background-image": "url(#{$scope.contribution.photo_src})"
  else
    $scope.bgImageStyle = {}

  #-----------------------------------------------------------------------------
  # CAMERA HANDLNG
  #-----------------------------------------------------------------------------

  # Camera failure callback
  cameraError = (message) ->
    Log.w "Capturing the photo failed: #{message}"

  # File system failure callback
  fileError = (error) ->
    Log.w "File system error: #{error}"

  # Move the selected photo from Cordova's default tmp folder to Steroids's user files folder
  imageUriReceived = (imageURI) ->
    window.resolveLocalFileSystemURI imageURI, gotFileObject, fileError

  gotFileObject = (file) ->
    # Define a target directory for our file in the user files folder
    # steroids.app variables require the Steroids ready event to be fired, so ensure that
    steroids.on "ready", ->
      targetDirURI = "file://" + steroids.app.absoluteUserFilesPath
      fileName = "contribution_photo_#{Session.userName()}_#{new Date().getTime()}.jpg"

      window.resolveLocalFileSystemURI(
        targetDirURI
        (directory) ->
          file.moveTo directory, fileName, fileMoved, fileError
        fileError
      )

    # Store the moved file's URL into $scope.contribution.photo_src
    fileMoved = (file) ->
      # localhost serves files from both steroids.app.userFilesPath and steroids.app.path
      # Log.d "File located at #{JSON.stringify file}"
      $scope.contribution.photo_file = file.toURL()
      $scope.contribution.photo_src = "/" + file.name
      $scope.bgImageStyle = "background-image": "url(#{$scope.contribution.photo_src})"
      $scope.$apply -> $scope.loading = false

  #-----------------------------------------------------------------------------
  # UI CALLBACKS
  #-----------------------------------------------------------------------------
  $scope.addPollOption = ->
    $scope.prompt = {}
    lblPollOption = T._ gettext "Poll option"

    prompt = $ionicPopup.show
      template: "<input type=\"text\" placeholder=\"#{lblPollOption}\" ng-model=\"prompt.poll_option\">"
      title: T._ gettext "Add poll option"
      subTitle: T._ gettext "Please enter in the field below."
      scope: $scope
      buttons: [
        text: T._ gettext "Cancel"
      ,
        text: T._ gettext "Add"
        type: "button-positive"
        onTap: (e) ->
          if not $scope.prompt.poll_option
            # Don't allow the user to close unless poll option is entered
            e.preventDefault()
          else
            return $scope.prompt.poll_option
      ]

    prompt.then (res) ->
      $scope.contribution.poll_options.push res if res

  $scope.removePollOption = (pollOption) ->
    $scope.contribution.poll_options = _.without $scope.contribution.poll_options, pollOption

  $scope.choosePhoto = (msg) ->
    lblTitle = if $scope.imgSrc then T._ gettext "Replace photo" else T._ gettext "Add a photo"

    if ionic.Platform.isAndroid()
      options =
        quality: 70
        destinationType: navigator.camera.DestinationType.IMAGE_URI
        correctOrientation: true
        targetWidth: 640

      navigator.camera.getPicture imageUriReceived, cameraError, options
    else
      actionSheet = $ionicActionSheet.show
        buttons: [
          text: T._ gettext "From library"
        ,
          text: T._ gettext "Capture photo"
        ]
        # destructiveText: T._ gettext "Delete"
        titleText: lblTitle
        cancelText: T._ gettext "Cancel"
        buttonClicked: (index) ->
          if not navigator.camera?
            Log.w "Camera API is not available"
            return true
          options = {}
          if index is 0
            options =
              quality: 70
              destinationType: navigator.camera.DestinationType.IMAGE_URI
              sourceType: navigator.camera.PictureSourceType.PHOTOLIBRARY
              correctOrientation: true # Let Cordova correct the picture orientation (WebViews don't read EXIF data properly)
              targetWidth: 640
              popoverOptions: # iPad camera roll popover position
                width: 768
                height: 190
                arrowDir: Camera.PopoverArrowDirection.ARROW_UP
          else
            options =
              quality: 70
              destinationType: navigator.camera.DestinationType.IMAGE_URI
              correctOrientation: true
              targetWidth: 640

          navigator.camera.getPicture imageUriReceived, cameraError, options
          return true

  $scope.removePhoto = ->
    $scope.contribution.photo_src = null
    $scope.bgImageStyle = {}

  $scope.chooseMood = ->
    $state.go "app.mood"

  $scope.choosePoi = ->
    $state.go "app.poi"

  $scope.chooseMission = ->
    $state.go "app.mission-select"

  $scope.createContribution = ->
    error = false

    # Check form
    error = not $scope.contribution.type or
    not $scope.contribution.title or
    ($scope.contribution.type is "PL" and $scope.contribution.poll_options.length < 2) or
    ($scope.contribution.type isnt "PL" and not $scope.contribution.description)

    if error
      alert = $ionicPopup.alert
        title: T._ gettext "Something is missing"
        template: T._ gettext "There's something missing, please check the comments in the form"
      alert.then (res) ->
        $scope.hasError = true
    else
      # Meta parameter incentive messages
      title = null
      msg = null
      if !$scope.contribution.photo_src?
        error = true
        title = T._ gettext "Do you want to include a photo?"
        msg = T._ gettext "Adding a photo gives your contribution more meaning!"
      else if !$scope.contribution.poi? or !$scope.contribution.mood?
        error = true
        title = T._ gettext "Do you want to provide additional information?"
        msg = T._ gettext "Adding your location and mood gives your contribution more meaning!"
        if $scope.contribution.mood?
          msg = T._ gettext "Adding your location gives your contribution more meaning!"
        else if $scope.contribution.poi?
          msg = T._ gettext "Adding your mood gives your contribution more meaning!"

      if error
        confirm = $ionicPopup.confirm
          title: title
          template: msg
          cancelText: T._ gettext "I'll edit first"
          cancelType: "button-positive"
          okText: T._ gettext "Continue anyway"
          okType: "button-default"
        confirm.then (res) ->
          if res
            continuePosting()
      else
        continuePosting()

  continuePosting = ->
    try
      mood = $scope.contribution.mood.code
    catch e
      mood = null

    try
      poi = $scope.contribution.poi.name
    catch e
      poi = null

    try
      mission_id = $scope.contribution.mission.id
    catch e
      mission_id = null
    
    $ionicLoading.show template: T._ gettext "Submitting contribution..."
    ContributionRestangular.all("contribution").post
      title: $scope.contribution.title
      type: $scope.contribution.type
      description: $scope.contribution.description
      mood: mood
      accuracy: localStorage.getItem "position.coords.accuracy"
      point: "POINT (#{$scope.contribution.latlng.lng} #{$scope.contribution.latlng.lat})"
      poi: poi
      mission: mission_id
      poll_options: $scope.contribution.poll_options
    .then (response) ->
      imageSrc = if $scope.contribution.photo_src? then $scope.contribution.photo_src else null

      Log.i "Contribution with id=#{response.id} was created"
      alert = $ionicPopup.alert
        title: T._ gettext "Successfully uploaded"
        templete: T._ gettext "Thanks, your contribution was uploaded."
      alert.then ->
        $scope.reset false
        Util.removeLastKnownMapBounds()
        $ionicNavBarDelegate.back()

      if imageSrc?
        Log.i "Uploading photo: #{imageSrc}"
        # Upload photo
        options = new FileUploadOptions()
        options.fileKey = "photo"
        options.fileName = imageSrc.substr imageSrc.lastIndexOf("/") + 1
        options.mimeType = "image/jpeg"

        params = contribution: response.id

        options.params = params
        options.headers = "Authorization": "Token #{Session.token()}"

        uploadSuccess = (response) ->
          Log.i "Photo was uploaded: #{imageSrc}"

        uploadError = (response) ->
          if response.code is FileTransferError.FILE_NOT_FOUND_ERR
            msg = "file not found"
          else if response.code is FileTransferError.INVALID_URL_ERR
            msg = "invalid URL"
          else if response.code is FileTransferError.CONNECTION_ERR
            msg = "connection error"
          else if response.code is FileTransferError.ABORT_ERR
            msg = "upload aborted"
          else
            msg = "unknown error"

          Log.e "Could not upload photo #{imageSrc}: #{msg}"

          alert = $ionicPopup.alert
            title: T._ gettext "Cannot upload photo"
            template: T._ gettext "Your contribution was uploaded without your photo."
          # alert.then (res) ->
          #   $scope.reset()

        ft = new FileTransfer()
        ft.upload $scope.contribution.photo_file, encodeURI("#{Config.API_ENDPOINT}/photo/"), uploadSuccess, uploadError, options, true
    , (response) ->
      Log.e "Contribution upload failed: #{JSON.stringify response.data}"
      alert = $ionicPopup.alert
        title: T._ gettext "Failed to upload"
        template: T._ gettext "Sorry, couldn't upload your contribution. Please try again later."
    .finally ->
      $ionicLoading.hide()

  $scope.setPoi = (poi) ->
    $scope.contribution.poi = poi

  $scope.setMood = (mood) ->
    $scope.contribution.mood = mood

  $scope.resetMood = ->
    $scope.contribution.mood = null

  $scope.resetConfirm = ->
    confirm = $ionicPopup.confirm
      title: T._ "Reset contribution"
      template: T._ "Do you really want to reset and discard this contribution?"
      okText: T._ gettext "Reset"
    confirm.then (res) ->
      if res
        $scope.reset true

  $scope.reset = (locate) ->
    $scope.removePhoto()

    previousLatLng = L.latLng contributionModel.latlng
    contributionModel.reset()
    # contributionModel.latlng = Util.lastKnownPosition()

    if locate
      $ionicLoading.show template: T._ gettext "Locating..."
      $cordovaGeolocation.getCurrentPosition
        enableHighAccuracy: ionic.Platform.isIOS()
        timeout: 5000
      .then (position) ->
        contributionModel.latlng = L.latLng position.coords.latitude, position.coords.longitude
        $scope.contribution = contributionModel
        currentPositionMarker.setLatLng $scope.contribution.latlng if currentPositionMarker?
        # $ionicLoading.hide()
      , (error) ->
        contributionModel.latlng = previousLatLng
        $scope.contribution = contributionModel
        # $ionicLoading.hide()
      .finally ->
        $ionicLoading.hide()

    $scope.hasError = false
    window.scrollTo 0, 0

  # $scope.goBack = ->
  #   console.log "goback"
  #   if $scope.contribution.isDirty()
  #     $ionicActionSheet.show 
  #     buttons: [
  #       text: "Save for later"
  #     ]
  #     destructiveText: T._ gettext "Discard"
  #     titleText: "Do you want to save the contribution to upload later?"
  #     buttonClicked: (index) ->
  #       $ionicNavBarDelegate.back()
  #     destructiveButtonClicked: ->
  #       $scope.reset()
  #       $ionicNavBarDelegate.back()
  #   else
  #     $ionicNavBarDelegate.back()

  #-----------------------------------------------------------------------------
  # INIT
  #-----------------------------------------------------------------------------
  # contributionModel.latlng = Util.lastKnownPosition() if not contributionModel.latlng?

  initMap = ->
    currentPositionMarker = Util.createPositionMarker contributionModel.latlng,
        size: 40
    map = new L.Map "contribution-map",
      attributionControl: false
      center: contributionModel.latlng
      zoom: 16
      zoomControl: false
    Util.disableMapInteraction map
    Util.createTileLayer().addTo map
    
    currentPositionMarker.addTo map

  if not contributionModel.isDirty()
    $ionicLoading.show template: T._ gettext "Locating..."
    $cordovaGeolocation.getCurrentPosition
      enableHighAccuracy: ionic.Platform.isIOS()
      timeout: 5000
    .then (position) ->
      contributionModel.latlng = L.latLng position.coords.latitude, position.coords.longitude
      initMap()
      # $ionicLoading.hide()
    , (error) ->
      Log.w "Cannot fetch position, assuming last known position"
      if Util.lastKnownPosition()
        contributionModel.latlng = Util.lastKnownPosition()
        initMap()
        # $ionicLoading.hide()
      else
        $ionicPopup.alert
          title: T._ gettext "Cannot determine location"
          template: "Please try again later"
        .then ->
          # $ionicLoading.hide()
          $ionicNavBarDelegate.back()
    .finally ->
      $ionicLoading.hide()
  else
    initMap()

#-------------------------------------------------------------------------------
# MoodCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "MoodCtrl", ($scope, $location, $anchorScroll, contributionModel) ->

  selectMood = (mood) ->
    contributionModel.mood = mood
    $scope.selectedMood = mood.code

  unselectMood = ->
    contributionModel.mood = null
    $scope.selectedMood = null

  $scope.choose = (mood) ->
    if $scope.selectedMood? and $scope.selectedMood is mood.code
      unselectMood()
    else
      selectMood mood

  $scope.reset = ->
    unselectMood()
    window.scrollTo 0, 0

  $scope.unselect = ->
    unselectMood()
  
  try
    $scope.selectedMood = contributionModel.mood.code

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()
  catch e
    $scope.selectedMood = null

#-------------------------------------------------------------------------------
# PoiCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "PoiCtrl", ($scope, $location, $anchorScroll, $ionicLoading, $ionicScrollDelegate, contributionModel, T, gettext, Util, Game, Log, UI, PoiRestangular) ->

  iconSize = [28, 42]
  iconAnchor = [14, 42]
  iconLongerSide = if iconSize[0] > iconSize[1] then iconSize[0] else iconSize[1]
  paddingTopLeft = [iconSize[0] / 2 + 10, iconSize[1] + 10]
  paddingBottomRight = [iconSize[0] / 2 + 10, 10]

  # latLngOnLocate = null
  currentPositionMarker = null

  selectedMarker = null
  selectedMarkerZIndex = 0
  maxZIndex = 0

  spiderfiedMarkers = null

  venuesLayer = null

  map = new L.Map "poi-map",
    attributionControl: false
    center: Util.lastKnownPosition()
    zoom: 10
    zoomControl: false

  oms = new OverlappingMarkerSpiderfier map,
    nearbyDistance: iconLongerSide

  updateCurrentPositionMarker = (latlng) ->
    if not currentPositionMarker?
      currentPositionMarker = Util.createPositionMarker latlng
      currentPositionMarker.addTo map
    currentPositionMarker.setLatLng latlng 

  unselectPois = ->
    selectedMarker._icon.style.zIndex = selectedMarkerZIndex unless selectedMarker is null
    _.each venuesLayer.getLayers(), (marker) -> marker._icon.className = marker._icon.className.replace " active", ""

    contributionModel.poi = null

    $scope.selectedPoi = null
    selectedMarker = null
    selectedMarkerZIndex = 0
    maxZIndex = 0

    map.fitBounds venuesLayer.getBounds(), paddingTopLeft: paddingTopLeft, paddingBottomRight: paddingBottomRight

  selectPoi = (poi) ->
    return if not venuesLayer? or not poi?
    
    $scope.selectedPoi = poi

    # Reset z-index of previously selected marker
    selectedMarker._icon.style.zIndex = selectedMarkerZIndex unless selectedMarker is null

    selectedMarker = null

    # Select marker in map
    _.each venuesLayer.getLayers(), (marker) ->
      # Reset style of all markers
      marker._icon.className = marker._icon.className.replace " active", ""

      selectedMarker = marker if marker.data.id is poi.id
      maxZIndex = marker._icon.style.zIndex if marker._icon.style.zIndex > maxZIndex

    if selectedMarker isnt null
      selectedMarkerZIndex = selectedMarker._icon.style.zIndex
      selectedMarker._icon.className += " active"
      selectedMarker._icon.style.zIndex = maxZIndex + 1

    latlng = new L.LatLng poi.location.lat, poi.location.lng
    map.setView latlng, map.getMaxZoom()
    # map.panTo latlng

    contributionModel.poi = poi

  # locate = ->
  #   map.locate setView: false
  #   $ionicLoading.show template: T._ gettext "Locating..."
   
  $scope.choose = (poi) ->
    if $scope.selectedPoi? and $scope.selectedPoi.id is poi.id
      unselectPois()
    else
      oms.unspiderfy()
      selectPoi poi

  $scope.reset = (keepSelected = false) ->
    if not keepSelected
      unselectPois()
      window.scrollTo 0, 0
    $scope.loadPois contributionModel.latlng

  $scope.unselect = ->
    unselectPois()

  $scope.loadPois = (latlng) ->
    $ionicLoading.show template: T._ gettext "Fetching venues..."
    PoiRestangular.all("venues/search").getList(ll: "#{latlng.lat},#{latlng.lng}", radius: Game.initialRadius, intent: "browse", limit: 10).then (result) ->
      $scope.pois = result.response.venues
      map.removeLayer venuesLayer unless venuesLayer is null
      venuesLayer = new L.FeatureGroup
      _.each result.response.venues, (venue) ->
        latlng = new L.LatLng venue.location.lat, venue.location.lng
        imgTag = ""
        if venue.categories[0]?
          imgSrc = "#{venue.categories[0].icon.prefix}44#{venue.categories[0].icon.suffix}"
          imgTag = "<img class=\"category-icon\" alt=\"#{venue.categories[0].name}\" src=\"#{imgSrc}\" width=\"22\">"
        poiMarker = new L.Marker latlng,
          icon: L.divIcon
            className: "poi-marker"
            iconAnchor: iconAnchor
            iconSize: iconSize
            html: "<div class=\"poi-icon\">#{imgTag}</div>"
        poiMarker.data = venue
        oms.addListener "click", (marker) ->
          if not _.contains spiderfiedMarkers, marker
            selectPoi marker.data

            # Scroll to selected element
            $location.hash marker.data.id
            $anchorScroll()
            $scope.$apply()

        venuesLayer.addLayer poiMarker
        oms.addMarker poiMarker

      map.addLayer venuesLayer
      map.fitBounds venuesLayer.getBounds(), paddingTopLeft: paddingTopLeft, paddingBottomRight: paddingBottomRight

      # Add current position marker
      updateCurrentPositionMarker latlng

      # Select previously selected POI again
      selectedMarker = null
      selectedMarkerZIndex = 0
      maxZIndex = 0
      selectPoi $scope.selectedPoi if $scope.selectedPoi?
    , (error) ->
      Log.e "Failed API call: #{error}"
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"
      $ionicScrollDelegate.resize()

  # map.on "locationfound", (e) ->
  #   $scope.loadPois e.latlng

  # map.on "locationerror", (e) ->
  #   Log.w "Failed to get current position: #{e.message}. Fetching venues from last know position."
  #   $scope.loadPois Util.lastKnownPosition()

  map.on "zoomend", (e) ->
    selectPoi $scope.selectedPoi if $scope.selectedPoi?

  map.on "click", (e) ->
    unselectPois()
    $scope.$apply()

  oms.addListener "spiderfy", (spiderfied, others) ->
    unselectPois()
    _.each others, (marker) ->
      marker._icon.className = marker._icon.className + " disabled"

    spiderfiedMarkers = spiderfied

  oms.addListener "unspiderfy", (unspiderfied, others) ->
    _.each venuesLayer.getLayers(), (marker) ->
      marker._icon.className = marker._icon.className.replace " disabled", ""

    unselectPois()
    spiderfiedMarkers = null

  # Init
  Util.disableMapInteraction map
  Util.createTileLayer().addTo map

  updateCurrentPositionMarker contributionModel.latlng
  $scope.selectedPoi = contributionModel.poi
  $scope.reset true

#-------------------------------------------------------------------------------
# ContributionListCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ContributionListCtrl", ($scope, $rootScope, $state, $timeout, $ionicLoading, $ionicScrollDelegate, $cordovaGeolocation, T, gettext, Session, Util, Log, Config, ContributionRestangular) ->
  changeTimeoutInMs = 300

  $scope.data = {}
  # $scope.data.minDistance = 100
  # $scope.data.maxDistance = 5000
  # $scope.data.initDistance = $scope.data.maxDistance # $scope.maxDistance * 0.75
  # $scope.data.distance = $scope.data.initDistance
  $scope.data.distance = 5000

  $scope.filter = "nearby"

  $scope.contributions = []
  $scope.baseUrl = Config.API_ENDPOINT 

  $scope.loadContributions = ->
    $ionicLoading.show template: T._ gettext "Loading contributions..."
    latlng = Util.lastKnownPosition()

    parameter = {}
    if $scope.filter is "nearby"
      parameter =
        distance: $scope.data.distance
        long: latlng.lng
        lat: latlng.lat
    else if $scope.filter is "latest"
      parameter = 
        filter: "latest"

    ContributionRestangular.all("contribution").getList(parameter).then (data) ->
      $scope.contributions = data

      # $rootScope.notifications_unread_count = (_.where data, { is_read: false }).length
      # console.log "hey" + (_.where data, { is_read: false }).length
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  $scope.openContribution = (contribution) ->
    $state.go "app.contribution-detail", id: contribution.id

  $scope.distanceChanged = ->
    # Wait if distance hasn't changed recently to avoid too many requests
    $scope.lastChangeInMs = Date.now()
    $timeout ->
      if Date.now() > ($scope.lastChangeInMs + changeTimeoutInMs)
        $scope.loadContributions()
    , changeTimeoutInMs

  $scope.pointDistance = (item) ->
    # console.log item
    matches = item.point.match /\d+\.?\d*|\.\d+/g
    latlng = L.latLng parseFloat(matches[1]), parseFloat(matches[0])
    return Util.lastKnownPosition().distanceTo latlng

  $scope.newContribution = ->
    $state.go "app.contribution-new"

  # Run

  $ionicLoading.show template: T._ gettext "Locating..."
  $cordovaGeolocation.getCurrentPosition
    enableHighAccuracy: ionic.Platform.isIOS()
    timeout: 2000
  .then (position) ->
    localStorage.setItem "position.coords.latitude", position.coords.latitude
    localStorage.setItem "position.coords.longitude", position.coords.longitude
    localStorage.setItem "position.coords.accuracy", position.coords.accuracy
    localStorage.setItem "position.timestamp", position.timestamp
    $ionicLoading.hide()
  , (error) ->
    Log.w "Couldn't fetch position, assuming last known position."    
  .finally ->
    $ionicLoading.hide()
    $scope.loadContributions()

#-------------------------------------------------------------------------------
# SettingsCtrl
#-------------------------------------------------------------------------------
mainApp.controller "SettingsCtrl", ($scope, $rootScope, amMoment, gettextCatalog) ->
  $scope.language = localStorage.getItem "language"

  $scope.chooseLanguage = (language) ->
    $rootScope.language = language
    $scope.language = language
    localStorage.setItem "language", language

    gettextCatalog.currentLanguage = language
    amMoment.changeLanguage language
    $rootScope.moods = $rootScope.getMoods()

#-------------------------------------------------------------------------------
# ProfileCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ProfileCtrl", ($scope, $state, $stateParams, $ionicLoading, T, gettext, Backend, Session) ->
  $scope.loadProfile = ->
    $ionicLoading.show template: T._ "Loading profile..."
    if $stateParams.username
      query = Backend.one("profile", $stateParams.username).get()
    else
      query = Backend.all("profile").customGET()

    query.then (data) ->
        $scope.profile = data
      .finally ->
        $ionicLoading.hide()
        $scope.$broadcast "scroll.refreshComplete"

  $scope.openContribution = (contribution) ->
    $state.go "app.contribution-detail", id: contribution.id

  $scope.isCustomProfile = if $stateParams.username then true else false
  $scope.username = Session.userName() 
  $scope.loadProfile()

#-------------------------------------------------------------------------------
# MissionListCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MissionListCtrl", ($scope, $state, $ionicPopup, $ionicLoading, T, gettext, Backend) ->
  $scope.loadMissions = ->
    $ionicLoading.show template: T._ "Loading missions..."
    Backend.all("missions").getList().then (data) ->
      $scope.missions = data
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  $scope.openMission = (mission) ->
    $state.go "app.mission-detail", id: mission.id

  $scope.help = ->
    $ionicPopup.alert
      title: T._ gettext "Mission"
      template: T._ gettext "Missions can be added to a contribution when you create them. Usually, missions have a specific and goal and can be active for a certain time. They will increase your area and lifetime."

  $scope.loadMissions()

#-------------------------------------------------------------------------------
# MissionDetailCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MissionDetailCtrl", ($scope, $state, $stateParams, $ionicLoading, T, gettext, Backend) ->
  $scope.mission = {}

  $scope.loadMission = (id) ->
    $ionicLoading.show template: T._ "Loading mission..."
    Backend.one("mission", id).get().then (data) ->
      $scope.mission = data
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  $scope.loadMission $stateParams.id

#-------------------------------------------------------------------------------
# MissionSelectCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "MissionSelectCtrl", ($scope, contributionModel, $ionicLoading, T, gettext, Backend) ->
  $scope.loadMissions = ->
    $ionicLoading.show template: T._ "Loading missions..."
    Backend.all("missions").getList().then (data) ->
      $scope.missions = data
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

  selectMission = (mission) ->
    contributionModel.mission = mission
    $scope.selectedMission = mission

  unselectMission = ->
    contributionModel.mission = null
    $scope.selectedMission = null

  $scope.choose = (mission) ->
    if $scope.selectedMission? and $scope.selectedMission.id is mission.id
      unselectMission()
    else
      selectMission mission

  $scope.unselect = ->
    unselectMission()
  
  $scope.selectedMission = contributionModel.mission
  $scope.loadMissions()

