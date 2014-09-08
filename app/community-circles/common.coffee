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

common.filter "area", ->
  return (input) ->
    try
      if input >= 1000000
        return (input/1000000).toFixed(2) + "km<sup>2</sup>"
      else
        return input.toFixed(0) + "m<sup>2</sup>"
    catch
      return input

common.filter "mood", ->
  return (input, moods) ->
    try
      return (_.find moods, (item) -> item.code is input).name
    catch e
      return input

common.filter "lifetime", ->
  return (input) ->
    try
      days = (input/1440.0).toFixed 2
      if days is 1.0
        return "#{days} day"
      else
        return "#{days} days"
    catch e
      return input

common.filter "minutes", ->
  return (input) ->
    try
      return "#{input} min"
    catch e
      return input
    
common.filter "gameRuleIcon", ->
  return (input) ->
    try
      if input.game_rule_area.indexOf("PHOTO") isnt -1
        return "ion-image"
      else if input.game_rule_area.indexOf("VOTE") isnt -1
        return "ion-ios7-heart"
      else if input.game_rule_area.indexOf("COMMENT") isnt -1
        return "ion-ios7-chatbubble"
      else if input.game_rule_area.indexOf("POI") isnt -1
        return "ion-location"
      else if input.game_rule_area.indexOf("MOOD") isnt -1
        return "ion-happy"
      else if input.game_rule_area.indexOf("MISSION") isnt -1
        return "ion-ribbon-b"
    catch e
      return input

#-------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------- 
common.constant "Config",
  GAME_MODE: true
  GAME_HEALTH_ALERT: 0.2
  SUPPORT_EMAIL: @config.SUPPORT_EMAIL
  API_ENDPOINT: @config.API_ENDPOINT
  REGEX_USERNAME: /^[a-zA-Z0-9\-\_\.]+$/
  REGEX_POINT: /\d+\.?\d*|\.\d+/g 
  VERSION: "v1.1.1"

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
  # if not $rootScope.positionWatcherId?
  #   $rootScope.positionWatcherId = navigator.geolocation.watchPosition (position) ->
  #     localStorage.setItem "position.coords.latitude", position.coords.latitude
  #     localStorage.setItem "position.coords.longitude", position.coords.longitude
  #     # localStorage.setItem "position.coords.altitude", position.coords.altitude
  #     localStorage.setItem "position.coords.accuracy", position.coords.accuracy
  #     # localStorage.setItem "position.coords.altitudeAccuracy", position.coords.altitudeAccuracy
  #     # localStorage.setItem "position.coords.heading", position.coords.heading
  #     # localStorage.setItem "position.coords.speed", position.coords.speed
  #     localStorage.setItem "position.timestamp", position.timestamp
  #   , (error) ->
  #     if error.message
  #       msg = ": #{error.message}"
  #     else
  #       msg = ""
  #     Log.w "Couldn't fetch position#{msg}"
  #   ,
  #     enableHighAccuracy: false
  #     timeout: 5000

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
common.factory "Account", ($q, Log, T, gettext, AccountRestangular, ContributionRestangular, NotificationRestangular, PhotoRestangular, Backend) ->
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
      Backend.setDefaultHeaders "Authorization": "Token #{data.token}"

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
common.factory "Util", (Config, Color) ->

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

  # setLastKnowPosition: (position) ->
  #   localStorage.setItem "position.coords.latitude", position.latitude
  #   localStorage.setItem "position.coords.longitude", position.longitude
  #   localStorage.setItem "position.coords.accuracy", position.accuracy
  #   localStorage.setItem "position.timestamp", position.timestamp

  lastKnownPosition: ->
    try
      lat = window.localStorage.getItem "position.coords.latitude"
      lng = window.localStorage.getItem "position.coords.longitude"
      return new L.LatLng lat, lng
    catch e
      # return new L.LatLng 48.1217811, 16.5633169 # Vienna calling!
      return false

  removeLastKnownMapBounds: ->
    localStorage.removeItem "map.bounds.west"
    localStorage.removeItem "map.bounds.south"
    localStorage.removeItem "map.bounds.east"
    localStorage.removeItem "map.bounds.north"

  lastKnownMapBounds: (latLngBounds) ->
    if latLngBounds
      localStorage.setItem "map.bounds.west", latLngBounds.getWest()
      localStorage.setItem "map.bounds.south", latLngBounds.getSouth()
      localStorage.setItem "map.bounds.east", latLngBounds.getEast()
      localStorage.setItem "map.bounds.north", latLngBounds.getNorth()
    else
      try
        west = parseFloat localStorage.getItem "map.bounds.west"
        south = parseFloat localStorage.getItem "map.bounds.south"
        east = parseFloat localStorage.getItem "map.bounds.east"
        north = parseFloat localStorage.getItem "map.bounds.north"
        southWest = L.latLng south, west
        northEast = L.latLng north, east
        return L.latLngBounds southWest, northEast
      catch e
        return null
    
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

  polarToCartesian: (centerX, centerY, radius, angleInDegrees) ->
    angleInRadians = (angleInDegrees - 90) * Math.PI / 180.0
    x: centerX + (radius * Math.cos(angleInRadians))
    y: centerY + (radius * Math.sin(angleInRadians))

  describeArc: (x, y, radius, startAngle, endAngle) ->
    start = this.polarToCartesian(x, y, radius, endAngle)
    end = this.polarToCartesian(x, y, radius, startAngle)
    arcSweep = (if endAngle - startAngle <= 180 then "0" else "1")
    d = [
      "M"
      start.x
      start.y
      "A"
      radius
      radius
      0
      arcSweep
      0
      end.x
      end.y
      "L"
      x
      y
      "L"
      start.x
      start.y
    ].join(" ")
    d

  createTileLayer: ->
    return L.tileLayer.provider "OpenStreetMap.BlackAndWhite",
      detectRetina: true
      maxNativeZoom: 18
      maxZoom: 22

  createPositionMarker: (latlng, { size } = {}) ->
    size ?= 20

    pm = new L.Marker latlng,
      icon: L.divIcon
        className: "current-position-marker"
        iconSize: [size, size]
        iconAnchor: [size / 2, size / 2]
        html: "<div class=\"current-position-marker-icon\"></div>"

    return pm

  createHomeMarker: (latlng) ->
    return L.marker latlng

  createContributionMarker: (latlng, contribution, size) ->
    size ?= 40
    if Config.GAME_MODE
      # Create arc svg for health
      healthDiv = document.createElement "div"
      healthSvg = document.createElement "svg"
      healthPath = document.createElement "path"

      healthSvg.setAttribute "width", size
      healthSvg.setAttribute "height", size
      healthSvg.className = "contribution-health"
      if contribution.health < Config.GAME_HEALTH_ALERT
        healthSvg.className += " animated infinite flash"

      healthPath.setAttribute "d", this.describeArc(size / 2.0, size / 2.0, size / 2.0, 0, 360.0 * contribution.health)
      healthPath.setAttribute "fill", if contribution.has_community then Color.ccMain else Color.ccLight

      healthSvg.appendChild healthPath
      healthDiv.appendChild healthSvg

      community_suffix = if contribution.has_community then "-community" else ""

      marker = new L.Marker latlng,
        icon: L.divIcon
          className: "contribution-marker"
          iconSize: [size, size]
          html: "#{healthDiv.innerHTML}<div class=\"contribution-icon contribution-game-icon-#{this.convertContributionType contribution.type}#{community_suffix}\"></div>"
    else
      marker = new L.Marker latlng,
        icon: L.divIcon
          className: "contribution-marker"
          iconSize: [size, size]
          html: "<div class=\"contribution-icon contribution-icon-#{this.convertContributionType contribution.type}\"></div>"
    
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
