mainApp = angular.module "mainApp", [
  "ionic",
  "common",
  "templates",
  "AccountModel",
  "ContributionModel",
  "NotificationModel",
  "PhotoModel",
  "PoiModel",
  "angularMoment",
  "gettext"
]

#-------------------------------------------------------------------------------
# Routes
#------------------------------------------------------------------------------- 
mainApp.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "login",
    url: "/login"
    templateUrl: "login.html"
    controller: "LoginCtrl"
  .state "app",
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
  $stateProvider.state "app.mood",
    url: "/mood"
    views:
      mainContent:
        templateUrl: "mood.html"
        controller: "MoodCtrl"
  $stateProvider.state "app.poi",
    url: "/poi"
    views:
      mainContent:
        templateUrl: "poi.html"
        controller: "PoiCtrl"

  $urlRouterProvider.otherwise "/app/map"

#-------------------------------------------------------------------------------
# Factory (shared models)
#-------------------------------------------------------------------------------
mainApp.factory "contributionModel", ->
  _object =
    title: null
    type: null
    description: null
    mood: null
    author: null
    user:
      id: null
      username: null
    accuracy: null
    point: null
    poi: null
    poll_options: []

  reset: ->
    _object =
      title: null
      type: null
      description: null
      mood: null
      author: null
      user:
        id: null
        username: null
      accuracy: null
      point: null
      poi: null
      poll_options: []

  return _object
#-------------------------------------------------------------------------------
# Init
#-------------------------------------------------------------------------------
mainApp.run ($rootScope, $templateCache, $ionicPlatform, T, gettext, Log, amMoment, gettextCatalog) ->
  Log.i "Running mainApp..."
  $ionicPlatform.ready ->
    # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
    # for form inputs)
    if window.cordova and window.cordova.plugins.Keyboard 
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar true

    if window.StatusBar
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault()

  # Set language

  # $rootScope.checkLanguage = -> 
  #   navigator.globalization.getPreferredLanguage (language) ->  
  #     console.log language.value
  #   ,
  #   ->
  #     console.log "no languate"
  # $rootScope.checkLanguage()

  $rootScope.language = "de"

  if $rootScope.language isnt "en"
    gettextCatalog.currentLanguage = $rootScope.language
    gettextCatalog.debug = true
    amMoment.changeLanguage $rootScope.language

  # Moods
  $rootScope.moods = [
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

  # Save last visited view
  $rootScope.$on "$stateChangeSuccess", (event, toState, toParams, fromState, fromParams) ->
    localStorage.setItem "last_visited", toState.name if toState.name in ["app.map", "app.notifications"]

#-------------------------------------------------------------------------------
# MainCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MainCtrl", ($scope, $state, $ionicSideMenuDelegate, Session) ->
  # $scope.toggleLeft = ->
  #   $ionicSideMenuDelegate.toggleLeft()

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
      $state.go "app.notifications"
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
      $state.go $state.go localStorage.getItem("last_visited") or "app.map"
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

  if Session.loggedIn()
    $state.go localStorage.getItem("last_visited") or "app.map"

#-------------------------------------------------------------------------------
# Map
#------------------------------------------------------------------------------- 
mainApp.controller "MapCtrl", ($scope, $http, $state, Game, Log, Config, Color, Util, UI, ContributionRestangular, PhotoRestangular) ->

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
      this._container = L.DomUtil.create "button", "button button-positive icon ion-pinpoint"
      L.DomEvent.addListener this._container, "click", (e) ->
        L.DomEvent.stopPropagation e
        locate()

      return this._container
      
  #-----------------------------------------------------------------------------
  # MAP
  #-----------------------------------------------------------------------------
  map = new L.Map "map",
    center: Util.lastKnownPosition()
    zoom: 14
    zoomControl: false

  map.on "click", (e) ->
    if contributionDetailVisible
      $scope.hideContributionDetail()
      $scope.$apply()

  map.on "locationfound", (e) ->
    # Log.i "Location found: #{e.latlng.lat}, #{e.latlng.lng}"
    loadContributions()
    updateCurrentPositionMarker e.latlng

  map.on "locationerror", (e) ->
    Log.w "Could not determine position (code=#{e.code}). #{e.message}"

  map.on "viewreset", (e) ->
    loadContributions()

  map.on "moveend", (e) ->
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
          # map.removeControl locateControl
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
  locate = ->
    map.locate
      setView: true
      enableHighAccuracy: true

  createContributionMarker = (feature, latlng) ->
    marker = new L.Marker latlng,
      icon: L.divIcon
        className: "contribution-marker"
        iconSize: [markerDiameter, markerDiameter]
        html: "<div class=\"contribution-icon contribution-icon-#{Util.convertContributionType feature.properties.type}\"></div>"
    return marker

  loadContributions =  ->
    return if $scope.contributionSelected

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
    .error ->
      Log.e "Could not load contributions"

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
    .error ->
      Log.e "Could not load communities"

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

  $scope.locate = ->
    locate()

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

    # map.addControl locateControl
    
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
  # document.ontouchmove = (e) -> e.preventDefault()
  # document.addEventListener "visibilitychange", onVisibilityChange, false

  # Prevent that map doesn't receive click events from contribution overlay
  L.DomEvent.disableClickPropagation document.getElementsByClassName("contribution-detail")[0]

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
    , (data) ->
      Log.e data
    .finally ->
      $ionicLoading.hide()
      $scope.$broadcast "scroll.refreshComplete"

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
      template: "<textarea placeholder=\"#{lblComments}\" ng-model=\"comment\"></textarea>"
      title: T._ gettext "Please enter a comment"
      scope: $scope
      buttons: [
        text: T._ gettext "Cancel"
      ,
        text: T._ gettext "Send"
        type: "button-positive"
        onTap: (e) ->
          if not $scope.comment
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
        creator: Session.userId()
      .then (response) ->
        $scope.loadContribution $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      $ionicPopup.alert
        title: T._ gettext "You have already voted"
        template: T._ gettext "...and removing votes isn't implemented yet ;)"

  $scope.hasVotedForContribution = ->
    return _.contains $scope.contribution.votes, Session.userName()

  $scope.voteComment = (comment) ->
    if not $scope.hasVotedForComment comment
      ContributionRestangular.all("votecomment").post
        comment: comment.id
        creator: Session.userId()
      .then (response) ->
        $scope.loadComments $scope.contribution.id
        $ionicPopup.alert title: T._ gettext "Thanks for voting"
    else
      $ionicPopup.alert
        title: T._ gettext "You have already voted"
        template: T._ gettext "...and removing votes isn't implemented yet ;)"

  $scope.hasVotedForComment = (comment) ->
    return _.contains comment.votes, Session.userName()

  $scope.votePollOption = (poll_option) ->
    if not $scope.hasVotedForPollOption poll_option
      ContributionRestangular.all("votepolloption").post
        poll_option: poll_option.id
        creator: Session.userId()
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
    return _.contains poll_option.votes, Session.userName()

  # Init
  # UI.listen $scope
  $scope.loadContribution $stateParams.id

#-------------------------------------------------------------------------------
# ContributionNewCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ContributionNewCtrl", ($scope, $http, $state, gettext, T, contributionModel, $ionicLoading, $ionicPopup, $ionicNavBarDelegate, Util, Log, Config, ContributionRestangular) ->
  console.log contributionModel
  # $scope.message_id = "contributionNewCtrl"

  $scope.bgImageStyle = {}
  $scope.hasError = false

  #-----------------------------------------------------------------------------
  # CONTRIBUTION PROPERTIES
  #-----------------------------------------------------------------------------
  $scope.contribution = contributionModel
  # $scope.contribution.poi = null
  # $scope.contribution.type = null
  # $scope.contribution.mood = null
  # $scope.contribution.poll_options = []

  #-----------------------------------------------------------------------------
  # CAMERA HANDLNG
  #-----------------------------------------------------------------------------
  $scope.imageSrc = null
  $scope.imageFullPath = null

  # Camera failure callback
  cameraError = (message) ->
    Log.w "Capturing the photo failed: #{message}"
    $scope.$apply -> $scope.loading = false

  # File system failure callback
  fileError = (error) ->
    Log.w "File system error: #{error}"
    $scope.$apply -> $scope.loading = false

  # Move the selected photo from Cordova's default tmp folder to Steroids's user files folder
  imageUriReceived = (imageURI) ->
    window.resolveLocalFileSystemURI imageURI, gotFileObject, fileError

  gotFileObject = (file) ->
    # Define a target directory for our file in the user files folder
    # steroids.app variables require the Steroids ready event to be fired, so ensure that
    steroids.on "ready", ->
      targetDirURI = "file://" + steroids.app.absoluteUserFilesPath
      fileName = "contribution_photo_#{Util.userName()}_#{new Date().getTime()}.jpg"

      window.resolveLocalFileSystemURI(
        targetDirURI
        (directory) ->
          file.moveTo directory, fileName, fileMoved, fileError
        fileError
      )

    # Store the moved file's URL into $scope.imageSrc
    fileMoved = (file) ->
      # localhost serves files from both steroids.app.userFilesPath and steroids.app.path
      # Log.d "File located at #{JSON.stringify file}"
      $scope.imageFullPath = file.fullPath
      $scope.imageSrc = "/" + file.name
      $scope.bgImageStyle = {
        "background-image": "url(#{$scope.imageSrc})"
      }
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
    navigator.notification.confirm T._ gettext "Select source below",
      (buttonIndex) ->
        return if buttonIndex is 3
        options = {}
        if buttonIndex is 1
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
        else if buttonIndex is 2
          options =
            quality: 70
            destinationType: navigator.camera.DestinationType.IMAGE_URI
            correctOrientation: true
            targetWidth: 640
        navigator.camera.getPicture imageUriReceived, cameraError, options
        $scope.$apply -> $scope.loading = true
      msg,
      ["From library", "Capture photo", "Cancel"]

  $scope.removePhoto = ->
    $scope.imageSrc = null
    $scope.bgImageStyle = {}

  $scope.chooseMood = ->
    $state.go "app.mood"

  $scope.choosePoi = ->
    $state.go "app.poi"

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
        template: T._gettext "There's something missing, please check the comments below."
      alert.then (res) ->
        $scope.hasError = true
    else
      # Meta parameter incentive messages
      title = null
      msg = null
      if !$scope.imageSrc?
        error = true
        title = T._ gettext "Do you want to include a photo?"
        msg = T._ gettext "Adding a photo gives your contribution more meaning!"
      else if !$scope.contribution.poi? or !$scope.contribution.mood?
        error = true
        title = T._ gettext "Do you want to provide additional information?"
        missing = T._ gettext "your location and mood"
        if $scope.contribution.mood?
          missing = T._ gettext "your location"
        else if $scope.contribution.poi?
          missing = T._ gettext "your mood"

        msg = T._ gettext "Adding #{missing} gives your contribution more meaning!"

      if error
        confirm = $ionicPopup.confirm
          title: title
          template: msg
        confirm.then (res) ->
          if res
            postContribution()
      else
        postContribution()

  postContribution = ->      
    mood = null
    try
      mood = $scope.contribution.mood.name
    catch e
      mood = null
    
    ContributionRestangular.all("contribution").post
      title: $scope.contribution.title
      type: $scope.contribution.type
      description: $scope.contribution.description
      mood: mood
      author: Util.userId()
      user:
        id: Util.userId()
        username: Util.userName()
      accuracy: window.localStorage.getItem "position.coords.accuracy"
      point: "POINT (#{Util.lastKnownPosition().lng} #{Util.lastKnownPosition().lat})"
      poi: $scope.contribution.poi
      poll_options: $scope.contribution.poll_options
    .then (response) ->

      Log.d "Contribution with id=#{response.id} was created"

      if $scope.imageSrc
        imageURI = $scope.imageSrc

        # Upload photo
        options = new FileUploadOptions()
        options.fileKey = "photo"
        options.fileName = imageURI.substr imageURI.lastIndexOf("/") + 1
        options.mimeType = "image/jpeg"

        params =
          creator: Util.userId()
          contribution: response.id

        options.params = params

        uploadSuccess = (response) ->
          alert = $ionicPopup.alert
            title: T._ gettext "Successfully uploaded"
            template: T._ gettext "Thanks, your contribution was uploaded."
          alert.then (res) ->
            $scope.reset()
            UI.send "mapIndexCtrl", "locate"
            $ionicNavBarDelegate.back()

        uploadError = (response) ->
          alert = $ionicPopup.alert
            title: T._ gettext "Cannot upload photo"
            template: T._ gettext "Your contribution was uploaded without your photo."
          alert.then (res) ->
            $scope.reset()
            UI.send "mapIndexCtrl", "locate"
            $ionicNavBarDelegate.back()

        ft = new FileTransfer()
        ft.upload $scope.imageFullPath, encodeURI("#{Config.API_ENDPOINT}/photo/"), uploadSuccess, uploadError, options
      else
        alert = $ionicPopup.alert
          title: T._ gettext "Successfully uploaded"
          templete: T._ gettext "Thanks, your contribution was uploaded."

        alert.then (res) ->
          $scope.reset()
          UI.send "mapIndexCtrl", "locate"
          $ionicNavBarDelegate.back()
        , 
    , (response) ->
      Log.e "Contribution upload failed: #{JSON.stringify response.data}"
      alert = $ionicPopup.alert
        title: T._ gettext "Failed to upload"
        template: T._ gettext "Sorry, couldn't upload your contribution. Please try again later."
      alert.then (res) ->
        $scope.reset()
        UI.send "mapIndexCtrl", "locate"

  $scope.setPoi = (poi) ->
    $scope.contribution.poi = poi

  $scope.setMood = (mood) ->
    $scope.contribution.mood = mood

  $scope.resetMood = ->
    $scope.contribution.mood = null

  $scope.reset = ->
    $scope.contribution = {}
    $scope.contribution.type = null
    $scope.contribution.poll_options = []
    $scope.removePhoto()

    UI.send "moodIndexCtrl", "reset"
    UI.send "poiIndexCtrl", "reset"

    $scope.hasError = false
    window.scrollTo 0, 0

  #-----------------------------------------------------------------------------
  # INIT
  #-----------------------------------------------------------------------------
  # document.addEventListener "visibilitychange", onVisibilityChange, false

  # Util.consume $scope

  # steroids.view.setBackgroundColor "#ffffff"

#-------------------------------------------------------------------------------
# MoodCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "MoodCtrl", ($scope, $location, $anchorScroll, contributionModel) ->
  
  # $scope.message_id = "moodIndexCtrl"
  # $scope.moods = moods

  selectMood = (mood) ->
    # UI.send "contributionNewCtrl", "setMood", mood
    contributionModel.mood = mood
    $scope.selectedMood = mood.code

  unselectMood = ->
    # UI.send "contributionNewCtrl", "resetMood"
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

  $scope.message_id = "poiIndexCtrl"

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
    center: Util.lastKnownPosition()
    zoom: 10
    zoomControl: false

  oms = new OverlappingMarkerSpiderfier map,
    nearbyDistance: iconLongerSide

  # visibilityChanged = ->
  #   # POIs are prefetched, however, reload if you moved too far
  #   # if document.visibilityState is "visible" and latLngOnLocate isnt null and Util.lastKnownPosition().distanceTo(latLngOnLocate) > Game.initialRadius / 4
  #   # Log.d "Distance since last visit: #{Util.lastKnownPosition().distanceTo(latLngOnLocate)}m"
  #   if not document.hidden
  #     $scope.reset true

  updateCurrentPositionMarker = (latlng) ->
    if not currentPositionMarker?
      currentPositionMarker = Util.createPositionMarker latlng
      currentPositionMarker.addTo map
    currentPositionMarker.setLatLng latlng

  unselectPois = ->
    selectedMarker._icon.style.zIndex = selectedMarkerZIndex unless selectedMarker is null
    _.each venuesLayer.getLayers(), (marker) -> marker._icon.className = marker._icon.className.replace " active", ""

    # UI.send "contributionNewCtrl", "setPoi", null
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

    # UI.send "contributionNewCtrl", "setPoi", poi.name
    contributionModel.poi = poi.name

  locate = ->
    map.locate setView: false
    $ionicLoading.show template: T._ gettext "Locating..."
   
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
    locate()

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

  map.on "locationfound", (e) ->
    $scope.loadPois e.latlng

  map.on "locationerror", (e) ->
    Log.w "Failed to get current position: #{e.message}. Fetching venues from last know position."
    $scope.loadPois Util.lastKnownPosition()

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

  updateCurrentPositionMarker Util.lastKnownPosition()
  $scope.selectedPoi = contributionModel.poi
  
  locate()

#-------------------------------------------------------------------------------
# ContributionListCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ContributionListCtrl", ($scope, $state, $timeout, $ionicLoading, $ionicScrollDelegate, T, gettext, Session, Util, Log, Config, ContributionRestangular) ->
  changeTimeoutInMs = 300

  $scope.minDistance = 100
  $scope.maxDistance = 3000
  $scope.initDistance = $scope.minDistance # $scope.maxDistance * 0.75
  $scope.filter = "nearby"

  $scope.data = {}
  $scope.data.distance = $scope.initDistance

  $scope.contributions = []
  $scope.baseUrl = Config.API_ENDPOINT 

  $scope.loadContributions = ->
    $ionicLoading.show template: T._ gettext "Loading contributions..."
    latlng = Util.lastKnownPosition()

    if $scope.filter is "nearby"
      parameter =
        distance: $scope.data.distance
        long: latlng.lng
        lat: latlng.lat
    else
      parameter = 
        author_id = Session.userId()

    ContributionRestangular.all("contribution").getList(parameter).then (data) ->
      $scope.contributions = data
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

  # Run
  $scope.loadContributions()
