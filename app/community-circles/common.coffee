#-------------------------------------------------------------------------------
# Modules
#-------------------------------------------------------------------------------
common = angular.module "common", ["communityCirclesLog", "gettext"]

angular.module("ng").filter "cut", ->
  (value, max, wordwise, tail) ->
    return "" unless value
    max = parseInt max, 10
    return value unless max
    return value if value.length <= max
    value = value.substr 0, max
    if wordwise
      lastspace = value.lastIndexOf " "
      value = value.substr 0, lastspace unless lastspace is -1
    value + (tail or "…")

#-------------------------------------------------------------------------------
# Filter
#-------------------------------------------------------------------------------
common.filter "distanceToMe", ->
    return (input) ->
      try
        matches = input.match /\d+\.?\d*|\.\d+/g
        latLngFrom = L.latLng parseFloat(localStorage.getItem "position.coords.latitude"), parseFloat(window.localStorage.getItem "position.coords.longitude")
        latLngTo = L.latLng parseFloat(matches[1]), parseFloat(matches[0])
        return latLngFrom.distanceTo latLngTo
      catch e
        return "NaN"

common.filter "distance", ->
  return (input) ->
    if input >= 1000
      return (input/1000).toFixed(2) + "km"
    else
      return input.toFixed(0) + "m"

common.filter "mood", ->
    return (input, moods) ->
      try
        return (_.find moods, (item) -> item.code is input).name
      catch e
        return input

#-------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------- 
common.constant "Config",
  SUPPORT_EMAIL: @config.SUPPORT_EMAIL
  API_ENDPOINT: @config.API_ENDPOINT
  REGEX_USERNAME: /^[a-zA-Z0-9\-\_\.]+$/
  REGEX_POINT: /\d+\.?\d*|\.\d+/g 
  VERSION: "v2.0.0"

common.constant "Key",
  FOURSQUARE_CLIENT_ID: @key.FOURSQUARE_CLIENT_ID
  FOURSQAURE_CLIENT_SECTRET: @key.FOURSQAURE_CLIENT_SECTRET
  NOKIA_APP_ID: @key.NOKIA_APP_ID
  NOKIA_APP_CODE: @key.NOKIA_APP_CODE

common.constant "Color", 
  ccLighter: "#3fd1d1"
  ccLight: "#00c8c8"
  ccMain: "#00a8b3"
  ccDark: "#004855"
  ccDarker: "#212b37"

#-------------------------------------------------------------------------------
# Run
#-------------------------------------------------------------------------------
common.run ($rootScope, gettextCatalog, gettext, Log, Color) ->
  # Check for config files
  if !@config? or !@key?
    alert "app/community-circles/private.coffee is missing or malformed!"

  # Fetch location in background
  if not $rootScope.positionWatcherId?
    $rootScope.positionWatcherId = navigator.geolocation.watchPosition (position) ->
      window.localStorage.setItem "position.coords.latitude", position.coords.latitude
      window.localStorage.setItem "position.coords.longitude", position.coords.longitude
      window.localStorage.setItem "position.coords.altitude", position.coords.altitude
      window.localStorage.setItem "position.coords.accuracy", position.coords.accuracy
      window.localStorage.setItem "position.coords.altitudeAccuracy", position.coords.altitudeAccuracy
      window.localStorage.setItem "position.coords.heading", position.coords.heading
      window.localStorage.setItem "position.coords.speed", position.coords.speed
      window.localStorage.setItem "position.timestamp", position.timestamp

  # Only allow portrait mode
  steroids.view.setAllowedRotations [0, 180]
  steroids.view.setBackgroundColor Color.ccMain

#-------------------------------------------------------------------------------
# Directives
#------------------------------------------------------------------------------- 
common.directive "imgLoadingSpinner", (Log) ->
  restrict: "A"
  link: (scope, element) ->
    width = 0
    height = 0
    isCircle = false
    wrapper = null
    spinner = null

    element.on "load", ->
      element.css visibility: "visible"
      spinner.style.display = "none"

    scope.$watch "ngSrc", ->
      width = element[0].getAttribute "width"
      height = element[0].getAttribute "height"
      isCircle = element[0].className.indexOf("img-circle") > -1

      wrapper = document.createElement "div"
      wrapper.style.width = "#{width}px"
      wrapper.style.height = "#{height}px"
      wrapper.style.display = "inline-block"
      wrapper.style.position = "relative"
      wrapper.className = if isCircle then "img-loading-spinner-wrapper img-circle" else "img-loading-spinner-wrapper"

      spinner = document.createElement "div"
      spinner.style.width = "#{width}px"
      spinner.style.height = "#{height}px"
      spinner.className = "img-loading-spinner"
      spinner.style.position = "absolute"
      
      wrapper.appendChild spinner
      element.wrap wrapper

      element.css visibility: "hidden"
      spinner.style.display = "block"

    scope.$on "$destroy", ->
      # Log.d "remove"
      angular.element(wrapper).remove()

# http://stackoverflow.com/questions/15207788/calling-a-function-when-ng-repeat-has-finished
common.directive "onFinishRender", ($timeout) ->
  restrict: "A"
  link: (scope, element, attr) ->
    if scope.$last is true
      $timeout ->
        scope.$emit "ngRepeatFinished"

#-------------------------------------------------------------------------------
# Translate
#-------------------------------------------------------------------------------
common.factory "T", (gettextCatalog) ->
  _: (str) ->
    return gettextCatalog.getString str

#-------------------------------------------------------------------------------
# Game
#-------------------------------------------------------------------------------
common.factory "Game", ->
  initialRadius: 100
  healthAlertThreshold: 0.2
    
#-------------------------------------------------------------------------------
# Session
#-------------------------------------------------------------------------------
common.factory "Account", ($q, Log, T, gettext, AccountRestangular, ContributionRestangular, NotificationRestangular, PhotoRestangular) ->
  login: (username, password) ->

    deferred = $q.defer()

    AccountRestangular.all("api-token-auth").post
      username: username
      password: password
    .then (data) ->
      # Save session
      localStorage.setItem "loggedIn", "true"
      localStorage.setItem "login.username", username
      localStorage.setItem "login.token", data.token

      # Set authorization token
      ContributionRestangular.setDefaultHeaders "Authorization": "Token #{data.token}"
      NotificationRestangular.setDefaultHeaders "Authorization": "Token #{data.token}"
      PhotoRestangular.setDefaultHeaders "Authorization": "Token #{data.token}"

      Log.i "User #{username} logged in"

      deferred.resolve()
    , (data) ->
      Log.e JSON.stringify data
      deferred.reject T._ gettext "Please check your credentials"

    return deferred.promise

  register: ({username, password, email}) ->
    deferred = $q.defer()

    if not username? or not password? or not email?
      deferred.reject T._ gettext "Registration not sufficient"
    else
      AccountRestangular.all("register").post
        username: username
        email: email
        password: password
      .then (data) ->      
        deferred.resolve data
      , (data) ->
        deferred.reject data

    return deferred.promise

  logout: ->
    userId = window.localStorage.getItem "login.user_id"
    username = window.localStorage.getItem "login.username"

    window.localStorage.setItem "loggedIn", "false"
    window.localStorage.removeItem "login.username"
    window.localStorage.removeItem "login.token"

    Log.i "User #{username} logged out"

common.factory "Session", (Log) ->
  # login: (username, token) ->
  #   window.localStorage.setItem "loggedIn", "true"
  #   window.localStorage.setItem "login.username", username
  #   window.localStorage.setItem "login.token", token

  #   Log.i "User #{username} logged in"

  # logout: ->
  #   userId = window.localStorage.getItem "login.user_id"
  #   username = window.localStorage.getItem "login.username"

  #   window.localStorage.setItem "loggedIn", "false"
  #   window.localStorage.removeItem "login.username"
  #   window.localStorage.removeItem "login.token"

  #   Log.i "User #{username} logged out"

  userName: ->
    return window.localStorage.getItem "login.username"

  token: ->
    return window.localStorage.getItem "login.token"

  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"

#-------------------------------------------------------------------------------
# UI
#-------------------------------------------------------------------------------
common.factory "UI", ->
  #-----------------------------------------------------------------------------
  # INTERWEBVIEW COMMUNICATION
  #-----------------------------------------------------------------------------
  # Example: `UI.send "myController", "sayHello", "World"` invokes the method
  # `$scope.sayHello "World"` in `myController`. This controller must have set
  # `$scope.message_id = "myController"` in order to receive the message. In the
  # controller `UI.listen $scope` can be called in order to automatically
  # receive messages and invike the corresponding method.
  #-----------------------------------------------------------------------------
  send: (to, command, params) ->
    msg =
      receiver: to
      command: command
      params: []

    # See http://coffeescriptcookbook.com/chapters/arrays/check-type-is-array
    typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is "[object Array]"

    if typeIsArray params
      _.each params, (p) ->
        msg.params.push p
    else if params?
      msg.params.push params

    window.postMessage msg

  listen: (scope) ->
    throw "$scope.message_id is not set" if not scope.message_id?
    window.addEventListener "message", (event) ->
      msg = event.data
      if msg.receiver is scope.message_id
        scope[msg.command].apply scope, msg.params
        scope.$apply()

#-------------------------------------------------------------------------------
# Util
#-------------------------------------------------------------------------------
common.factory "Util", ->

  convertContributionType: (code) ->
    if code is "ID"
      return "idea"
    else if code is "IS"
      return "issue"
    else if code is "OP"
      return "opinion"
    else if code is "PL"
      return "poll"
    else
      return "unknown"

  formatAreaSqKm: (area) ->
    return "#{(area/1000000).toFixed(2)}"

  lastKnownPosition: ->
    try
      lat = window.localStorage.getItem "position.coords.latitude"
      lng = window.localStorage.getItem "position.coords.longitude"
      return new L.LatLng lat, lng
    catch e
      return new L.LatLng 48.1217811, 16.5633169 # Vienna calling!

  randomFromTo: (from, to, float = false) ->
    rand = Math.random() * (to - from + 1) + from
    rand = Math.floor rand if not float
    return rand
    
  #-----------------------------------------------------------------------------
  # MAP HELPERS
  #-----------------------------------------------------------------------------
  meanLatLngs: (latlngs) ->
      lat = 0
      lng = 0

      _.each latlngs, (ll) ->
        lat += ll.lat
        lng += ll.lng

      lat /= latlngs.length
      lng /= latlngs.length

      return new L.LatLng lat, lng

  getBoundsForMarkers: (markers) ->
    minLat = Number.MAX_VALUE
    minLng = Number.MAX_VALUE
    maxLat = Number.MIN_VALUE
    maxLng = Number.MIN_VALUE

    _.each markers, (marker) ->
      minLat = Math.min marker.getLatLng().lat, minLat
      minLng = Math.min marker.getLatLng().lng, minLng
      maxLat = Math.max marker.getLatLng().lat, maxLat
      maxLng = Math.max marker.getLatLng().lng, maxLng

    return L.latLngBounds new L.LatLng(minLat, minLng), new L.LatLng(maxLat, maxLng)

  createTileLayer: ->
    return L.tileLayer.provider "OpenStreetMap.BlackAndWhite",
      detectRetina: true

  createPositionMarker: (latlng, { size } = {}) ->
    size ?= 20

    pm = new L.Marker latlng,
      icon: L.divIcon
        className: "current-position-marker"
        iconSize: [size, size]
        iconAnchor: [size / 2, size / 2]
        html: "<div class=\"current-position-marker-icon\"></div>"

    return pm

  createContributionMarker: (latlng, type) ->
    marker = new L.Marker latlng,
      icon: L.divIcon
        className: "contribution-marker"
        iconSize: [40, 40]
        html: "<div class=\"contribution-icon contribution-icon-#{this.convertContributionType type}\"></div>"
    return marker

  disableMapInteraction: (map) ->
    map.dragging.disable()
    map.touchZoom.disable()
    map.doubleClickZoom.disable()
    map.scrollWheelZoom.disable()
    map.tap.disable() if map.tap

  enableMapInteraction: (map) ->
    map.dragging.enable()
    map.touchZoom.enable()
    map.doubleClickZoom.enable()
    map.scrollWheelZoom.enable()
    map.tap.enable() if map.tap

  pointToLatLng: (point) ->
    try
      matches = point.match /\d+\.?\d*|\.\d+/g
      return L.latLng parseFloat(matches[1]), parseFloat(matches[0])
    catch e
      return null

  generateRandomContributions: (latLngBounds, n) ->
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
      type: ["IS", "ID", "PL", "OP"][Math.round(Math.random() * 3)]
      mood: "happy"
      radius: Util.randomFromTo 50, 300
      health: Math.random()
      community_id: 0
      creator: "ulrichson"
      craeted: new Date()
    ) for i in [1..n]
