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
# Constants
#------------------------------------------------------------------------------- 
common.constant "Config",
  SUPPORT_EMAIL: @config.SUPPORT_EMAIL
  API_ENDPOINT: @config.API_ENDPOINT
  REGEX_USERNAME: /^[a-zA-Z0-9\-\_\.]+$/
  VERSION: "v1.6.2"

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
common.run (Log, Color) ->
  if !@config? or !@key?
    alert "app/community-circles/private.coffee is missing or malformed!"

  # Fetch location
  onDeviceReady = ->
    if not $scope.positionWatcherId?
      $scope.positionWatcherId = navigator.geolocation.watchPosition (position) ->
        window.localStorage.setItem "position.coords.latitude", position.coords.latitude
        window.localStorage.setItem "position.coords.longitude", position.coords.longitude
        window.localStorage.setItem "position.coords.altitude", position.coords.altitude
        window.localStorage.setItem "position.coords.accuracy", position.coords.accuracy
        window.localStorage.setItem "position.coords.altitudeAccuracy", position.coords.altitudeAccuracy
        window.localStorage.setItem "position.coords.heading", position.coords.heading
        window.localStorage.setItem "position.coords.speed", position.coords.speed
        window.localStorage.setItem "position.timestamp", position.timestamp

  document.addEventListener "deviceready", onDeviceReady, false

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
      Log.d "remove"
      angular.element(wrapper).remove()

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
common.factory "Session", (Log) ->
  login: (username, userId) ->
    window.localStorage.setItem "loggedIn", "true"
    window.localStorage.setItem "login.username", username
    window.localStorage.setItem "login.user_id", userId

    Log.i "User #{username} with id=#{userId} logged in (localStorage: login.user_id=#{window.localStorage.getItem "login.user_id"}, login.username=#{window.localStorage.getItem "login.username"})"

  logout: ->
    userId = window.localStorage.getItem "login.user_id"
    username = window.localStorage.getItem "login.username"

    window.localStorage.setItem "loggedIn", "false"
    window.localStorage.removeItem "login.username"
    window.localStorage.removeItem "login.user_id"

    Log.i "User #{username} with id=#{userId} logged out (localStorage: login.user_id=#{window.localStorage.getItem "login.user_id"}, login.username=#{window.localStorage.getItem "login.username"})"

  userId: ->
    return window.localStorage.getItem "login.user_id"

  userName: ->
    return window.localStorage.getItem "login.username"

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
      lat = window.localStorage.getItem position.coords.latitude
      lng = window.localStorage.getItem position.coords.longitude
      return new L.LatLng lat, lng
    catch e
      return new L.LatLng 48.1217811, 16.5633169 # Vienna calling!

  randomFromTo: (from, to, float = false) ->
    rand = Math.random() * (to - from + 1) + from
    rand = Math.floor rand if not float
    return rand
