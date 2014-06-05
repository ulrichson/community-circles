communityCirclesUtil = angular.module "communityCirclesUtil", ["communityCirclesLog"]

communityCirclesUtil.directive "imgLoadingSpinner", (Log) ->
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

# Executed for each module that includes Util
communityCirclesUtil.run (Log) ->
  if !@config? or !@key?
    alert "app/community-circles/private.coffee is missing or malformed!"

  # Only allow portrait mode
  steroids.view.setAllowedRotations [0, 180]

  # Track UI visibility changes
  onDeviceReady = ->
    uiInfo = "[Date: #{(new Date()).toISOString()}; Location: #{window.location.href}; ViewId: #{window.AG_VIEW_ID}; ScreenId: #{window.AG_SCREEN_ID}]"
    deviceInfo = "[Model: #{window.device.model}; Cordova: #{window.device.cordova}; Platform: #{window.device.platform}; UUID: #{window.device.uuid}; Version: #{window.device.version}]"
    trackVisibilityChange = ->
      steroids.logger.log "#{uiInfo} #{deviceInfo} #{document.visibilityState} (hidden=#{document.hidden})"
    document.addEventListener "visibilitychange", trackVisibilityChange, false
  document.addEventListener "deviceready", onDeviceReady, false

communityCirclesUtil.constant "Config",
  SUPPORT_EMAIL: @config.SUPPORT_EMAIL
  API_ENDPOINT: @config.API_ENDPOINT
  REGEX_USERNAME: /^[a-zA-Z0-9\-\_\.]+$/
  VERSION: "v1.0.4"

communityCirclesUtil.constant "Key",
  FOURSQUARE_CLIENT_ID: @key.FOURSQUARE_CLIENT_ID
  FOURSQAURE_CLIENT_SECTRET: @key.FOURSQAURE_CLIENT_SECTRET
  NOKIA_APP_ID: @key.NOKIA_APP_ID
  NOKIA_APP_CODE: @key.NOKIA_APP_CODE

communityCirclesUtil.factory "UI", ->
  alert: ({title, message, buttonName, alertCallback} = {}) ->
    title ?= new String()
    message ?= new String()
    buttonName ?= "Ok"
    alertCallback ?= null

    navigator.notification.alert message, alertCallback, title, buttonName

  autoRestoreView: ({ navigationBar, backgroundColor }  = {}) ->
    navigationBar ?= true
    backgroundColor ?= "#ffffff"

    restore = ->
      if navigationBar
        steroids.view.navigationBar.show()
      else
        steroids.view.navigationBar.hide()

      steroids.view.setBackgroundColor backgroundColor

    onVisibilityChange = ->
      if !document.hidden
        restore()

    document.addEventListener "visibilitychange", onVisibilityChange, false

    restore()

communityCirclesUtil.factory "Util", (Key, Log) ->

  # Color scheme
  ccLighter: "#3fd1d1"
  ccLight: "#00c8c8"
  ccMain: "#00a8b3"
  ccDark: "#004855"
  ccDarker: "#212b37"

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
      pos = JSON.parse window.localStorage.getItem "lastKnownPosition"
      return new L.LatLng pos.coords.latitude, pos.coords.longitude
    catch e
      return new L.LatLng 48.1217811, 16.5633169 # Vienna calling!

  randomFromTo: (from, to, float = false) ->
    rand = Math.random() * (to - from + 1) + from
    rand = Math.floor rand if not float
    return rand

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

    steroids.view.setBackgroundColor "#00a8b3"
    loginView = new steroids.views.WebView
      location: ""
      id: "loginView"
      
    steroids.layers.push
      view: loginView
      navigationBar: false
      tabBar: false
      animation: new steroids.Animation
        transition: "flipHorizontalFromRight"

  userId: ->
    return window.localStorage.getItem "login.user_id"

  userName: ->
    return window.localStorage.getItem "login.username"

  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"

  #-----------------------------------------------------------------------------
  # UI HELPERS
  #-----------------------------------------------------------------------------
  preloadViews: ->
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
      id: "showContributionView"
    showContributionWebView.preload()

    poiWebView = new steroids.views.WebView
      location: "/views/poi/index.html"
      id: "poiView"
    poiWebView.preload()

    loginWebView = new steroids.views.WebView
      location: "/views/login/index.html"
      id: "loginView"
    loginWebView.preload()

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
    # return L.tileLayer "http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png",
    #   detectRetina: true
    #   reuseTiles: true
    #   subdomains: "a b c d".split " "
    #   unloadInvisibleTiles: false
    #   updateWhenIdle: true

    # return L.tileLayer "http://{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.png",
    #   detectRetina: true
    #   reuseTiles: true
    #   subdomains: "otile1 otile2 otile3 otile4".split " "
    #   unloadInvisibleTiles: false
    #   updateWhenIdle: true

    return L.tileLayer.provider "HERE.terrainDayMobile",
      app_code: Key.NOKIA_APP_CODE
      app_id: Key.NOKIA_APP_ID
      detectRetina: true

  createPositionMarker: (latlng, { radius, size } = {}) ->
    radius ?= null
    size ?= 20

    positionMarker = new L.LayerGroup

    if radius?
      c = new L.Circle latlng, radius,
        color: "#004855"
        fill: true
        fillColor: "#004855"
        fillOpacity: 0.2
        opacity: 1
        weight: 0
      positionMarker.addLayer c

    pm = new L.Marker latlng,
      icon: L.divIcon
        className: "current-position-marker"
        iconSize: [size, size]
        iconAnchor: [size / 2, size / 2]
        html: "<div class=\"current-position-marker-icon\"></div>"
    positionMarker.addLayer pm

    return positionMarker

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

  #-----------------------------------------------------------------------------
  # INTERWEBVIEW COMMUNICATION
  #-----------------------------------------------------------------------------
  # Example: `Util.send "myController", "sayHello", "World"` invokes the method
  # `$scope.sayHello "World"` in `myController`. This controller must have set
  # `$scope.message_id = "myController"` in order to receive the message. In the
  # controller `Util.consume $scope` can be called in order to automatically
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

  consume: (scope) ->
    throw "$scope.message_id is not set" if not scope.message_id?
    window.addEventListener "message", (event) ->
      msg = event.data
      if msg.receiver is scope.message_id
        scope[msg.command].apply scope, msg.params
        scope.$apply()

  #-----------------------------------------------------------------------------
  # VIEW NAVIGATION
  #-----------------------------------------------------------------------------
  enter: (viewId, { navigationBar, tabBar } = {}) ->
    navigationBar ?= true
    tabBar ?= true

    steroids.layers.push
      navigationBar: navigationBar
      tabBar: tabBar
      view: new steroids.views.WebView
        location: ""
        id: viewId

  return: ->
    steroids.layers.pop()

communityCirclesUtil.controller "MessageCtrl", ($scope, Log) ->

  states = null
  $scope.connectionIsNone = false

  setConnectivityMessage = ->

    return if !Connection?

    if !states
      states = {}
      states[Connection.UNKNOWN]  = "not available"
      states[Connection.ETHERNET] = "Ethernet"
      states[Connection.WIFI]     = "WiFi"
      states[Connection.CELL]     = "Cell"
      states[Connection.CELL_2G]  = "Cell 2G"
      states[Connection.CELL_3G]  = "Cell 3G"
      states[Connection.CELL_4G]  = "Cell 4G"
      states[Connection.NONE]     = "none"

    networkState = navigator.connection.type
    # DO NOT SET THIS MESSAGE
    # Callback seems to be buggy, it fires "online", although iOS 7.1 is in Airplane Mode
    # $scope.connectionIsNone = networkState is Connection.NONE
    # Log.d "Connection type is #{states[networkState]}"
    # $scope.$apply()

  # Check for internet connection
  onDeviceReady = ->
    setConnectivityMessage()
    document.addEventListener "online", setConnectivityMessage, false
    document.addEventListener "offline", setConnectivityMessage, false

  document.addEventListener "deviceready", onDeviceReady, false
  document.addEventListener "visibilitychange", setConnectivityMessage, false

# http://stackoverflow.com/questions/18095727/how-can-i-limit-the-length-of-a-string-that-displays-with-when-using-angularj
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
