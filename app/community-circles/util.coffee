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

  meanLatLngs: (latlngs) ->
      lat = 0
      lng = 0

      _.each latlngs, (ll) ->
        lat += ll.lat
        lng += ll.lng

      lat /= latlngs.length
      lng /= latlngs.length

      return new L.LatLng lat, lng

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
        msg.params.push JSON.stringify p
    else if params?
      msg.params.push JSON.stringify params

    window.postMessage msg

  consume: (scope) ->
    throw "$scope.message_id is not set" if not scope.message_id?
    window.addEventListener "message", (event) ->
      msg = event.data
      if msg.receiver is scope.message_id
        scope[msg.command].apply scope, msg.params

  #-----------------------------------------------------------------------------
  # VIEW NAVIGATION
  #-----------------------------------------------------------------------------
  enter: (viewId) ->
    steroids.layers.push new steroids.views.WebView
      location: ""
      id: viewId

  return: ->
    steroids.layers.pop()