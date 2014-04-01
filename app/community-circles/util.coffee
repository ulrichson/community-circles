communityCirclesUtil = angular.module("communityCirclesUtil", [])
communityCirclesUtil.factory "Util", ->

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

  createPositionMarker: (latlng, radius, size = 40) ->
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
  enter: (viewId) ->
    steroids.layers.push new steroids.views.WebView
      location: ""
      id: viewId

  return: ->
    steroids.layers.pop()