communityCirclesUtil = angular.module "communityCirclesUtil", ["communityCirclesLog"]

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

communityCirclesUtil.factory "Util", ->

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

  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"

  login: ->
    window.localStorage.setItem "loggedIn", "true"

  userId: ->
    return 1

  userName: ->
    return "ulrichson"

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
      id: "mapShowContributionView"
    showContributionWebView.preload()

    poiWebView = new steroids.views.WebView
      location: "/views/poi/index.html"
      id: "poiView"
    poiWebView.preload()

    loginWebView = new steroids.views.WebView
      location: "/views/login/index.html"
      id: "loginView"
    loginWebView.preload()

  logout: ->
    window.localStorage.setItem "loggedIn", "false"
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

  autoRestoreView: ({ navigationBar }  = {}) ->
    navigationBar ?= true

    restore = ->
      if navigationBar
        steroids.view.navigationBar.show()
      else
        steroids.view.navigationBar.hide()

      steroids.view.setBackgroundColor "#00a8b3"

    onVisibilityChange = ->
      if !document.hidden
        # alert "restore"
        restore()

    document.addEventListener "visibilitychange", onVisibilityChange, false

    restore()

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
    return L.tileLayer "http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png",
      detectRetina: true
      # maxNativeZoom: 18
      # maxZoom: 20
      reuseTiles: true
      subdomains: "a b c d".split " "
      unloadInvisibleTiles: false
      updateWhenIdle: true

    # return L.tileLayer "http://{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.png",
    #   detectRetina: true
    #   reuseTiles: true
    #   subdomains: "otile1 otile2 otile3 otile4".split " "
    #   unloadInvisibleTiles: false
    #   updateWhenIdle: true

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
    Log.d "Connection type is #{states[networkState]}"
    $scope.$apply()

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
