communityCirclesUtil = angular.module("communityCirclesUtil", [])
communityCirclesUtil.factory "Util", ->

  formatAreaSqKm: (area) ->
    return "#{(area/1000).toFixed(2)}"

  lastKnownPosition: ->
    try
      pos = JSON.parse window.localStorage.getItem "lastKnownPosition"
      return new L.LatLng pos.coords.latitude, pos.coords.longitude
    catch e
      return new L.LatLng 48.1217811, 16.5633169

    