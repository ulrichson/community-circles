mainApp = angular.module "mainApp", [
  "ionic",
  "common",
  "AccountModel",
  "ContributionModel",
  "NotificationModel",
  "MoodModel",
  "PhotoModel",
  "angularMoment",
  "gettext"
]

mainApp.run ($rootScope, amMoment, gettextCatalog) ->
  language = "de"

  if language isnt "en"
    gettextCatalog.currentLanguage = language
    gettextCatalog.debug = true
    amMoment.changeLanguage language

  $rootScope.$on "$stateChangeSuccess", (event, toState, toParams, fromState, fromParams) ->
    localStorage.setItem "last_visited", toState.name if toState.name isnt "login"

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
  .state "navigation.contribution-new",
    url: "/contribution-new"
    views:
      menuContent:
        templateUrl: "contribution.new.html"
        controller: "ContributionNewCtrl"
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
  # $stateProvider.state "mood",
  #   url: "/mood"
  #   views:
  #     menuContent:
  #       templateUrl: "mood.html"
  #       controller: "MoodCtrl"

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
      $state.go "navigation.notifications"
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
      $state.go $state.go localStorage.getItem("last_visited") or "navigation.map"
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
    $state.go localStorage.getItem("last_visited") or "navigation.map"

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
  # locateControl = null

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
    $state.go "navigation.contribution-new"

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

#-------------------------------------------------------------------------------
# ContributionNewCtrl
#-------------------------------------------------------------------------------
mainApp.controller "ContributionNewCtrl", ($scope, $http, $state, gettext, T, $ionicLoading, $ionicPopup, Util, Log, Config, ContributionRestangular) ->
  $scope.message_id = "contributionNewCtrl"

  $scope.loading = false
  $scope.bgImageStyle = {}
  $scope.hasError = false

  #-----------------------------------------------------------------------------
  # CONTRIBUTION PROPERTIES
  #-----------------------------------------------------------------------------
  $scope.contribution = {}
  $scope.contribution.poi = null
  $scope.contribution.type = null
  $scope.contribution.mood = null
  $scope.contribution.poll_options = []

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
    # alert $scope.contribution.poll_option
    $scope.contribution.poll_options.push $scope.contribution.poll_option
    $scope.contribution.poll_option = ""

  $scope.addPollOptionPrompt = ->
    onPrompt = (results) ->
      if results.buttonIndex is 1
        $scope.contribution.poll_options.push results.input1 if results.input1 isnt ""
        $scope.$apply()
    navigator.notification.prompt "Please enter in the field below.", onPrompt, "Add poll option", ["Add", "Cancel"], new String()

  $scope.removePollOption = (pollOption) ->
    $scope.contribution.poll_options = _.without $scope.contribution.poll_options, pollOption

  $scope.choosePhoto = (msg) ->
    navigator.notification.confirm "Select source below",
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
    $state.go "mood"

  $scope.choosePoi = ->
    Util.enter "poiView"

  $scope.close = ->
    Util.return()

  $scope.create = ->
    $scope.$apply -> $scope.loading = true

    mood = null
    try
      mood = $scope.contribution.mood.name
    catch e
      mood = null
    
    ContributionRestangular.all("contribution").post(
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
    ).then (response) ->

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
          navigator.notification.alert T._ gettext "Thanks, your contribution was uploaded."
          , ->
            $scope.loading = false
            $scope.reset()
            $scope.$apply()
            Util.send "mapIndexCtrl", "locate"
            Util.return()
          , "Successfully uploaded"

        uploadError = (response) ->
          navigator.notification.alert T._ gettext "Your contribution was uploaded without your photo.\nYou can add it later. #{JSON.stringify response}"
          , ->
            $scope.loading = false
            $scope.reset()
            $scope.$apply()
            Util.return()
          , "Photo missing"

        # Log.d "#{imageURI}: #{JSON.stringify options}"

        ft = new FileTransfer()
        ft.upload $scope.imageFullPath, encodeURI("#{Config.API_ENDPOINT}/photo/"), uploadSuccess, uploadError, options
      else
        navigator.notification.alert T._ gettext "Thanks, your contribution was uploaded."
        , ->
          $scope.loading = false
          $scope.reset()
          $scope.$apply()
          Util.return()
        , "Successfully uploaded"
    , (response) ->
      Log.e "Contribution upload failed: #{JSON.stringify response.data}"
      navigator.notification.alert T._ gettext "Sorry, couldn't upload your contribution. Please try again later."
      , ->
        $scope.loading = false
        $scope.$apply()
      , T._ gettext "Failed to upload"

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

    Util.send "moodIndexCtrl", "reset"
    Util.send "poiIndexCtrl", "reset"

    $scope.hasError = false
    window.scrollTo 0, 0


  #-----------------------------------------------------------------------------
  # EVENTS
  #-----------------------------------------------------------------------------
  onConfirm = (buttonIndex) ->
    if buttonIndex is 2
      return
    else if buttonIndex is 1
      $scope.create()

  # buttonAdd.onTap = ->
  #   error = false

  #   # Check form
  #   error = not $scope.contribution.type or
  #   not $scope.contribution.title or
  #   ($scope.contribution.type is "PL" and $scope.contribution.poll_options.length < 2) or
  #   ($scope.contribution.type isnt "PL" and not $scope.contribution.description)

  #   if error
  #     alertCallback = ->
  #       $scope.hasError = true
  #       $scope.$apply()
  #     navigator.notification.alert "Oops, there's something missing!\nPlease check the comments below.", alertCallback, "Something is missing", "Got it!"
  #   else
  #     # Meta parameter incentive messages
  #     title = null
  #     msg = null
  #     if !$scope.imageSrc?
  #       error = true
  #       title = T._ gettext "Do you want to include a photo?"
  #       msg = T._ gettext "Adding a photo gives your contribution more meaning and increases your radius!"
  #     else if !$scope.contribution.poi? or !$scope.contribution.mood?
  #       error = true
  #       title = T._ gettext "Do you want to provide additional information?"
  #       missing = T._ gettext "your location and mood"
  #       if $scope.contribution.mood?
  #         missing = T._ gettext "your location"
  #       else if $scope.contribution.poi?
  #         missing = T._ gettext "your mood"

  #       msg = T._ gettext "Adding #{missing} gives your contribution more meaning and increases your radius!"

  #     if error
  #       navigator.notification.confirm msg, onConfirm, title, ["Proceed anyway", "Edit contribution"]
  #     else
  #       $scope.create()

  #-----------------------------------------------------------------------------
  # INIT
  #-----------------------------------------------------------------------------
  # document.addEventListener "visibilitychange", onVisibilityChange, false

  # Util.consume $scope

  # steroids.view.setBackgroundColor "#ffffff"

#-------------------------------------------------------------------------------
# MoodCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "MoodCtrl", ($scope, $location, $anchorScroll, UI, MoodRestangular) ->
  
  $scope.message_id = "moodIndexCtrl"

  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()

  selectMood = (mood) ->
    UI.send "contributionNewCtrl", "setMood", mood
    $scope.selectedMood = mood.code

  unselectMood = ->
    UI.send "contributionNewCtrl", "resetMood"
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

  UI.listen $scope
