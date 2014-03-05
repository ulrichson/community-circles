# class window.Util
#   @formatAreaHtml: (area) ->
#     return "#{(area/1000).toFixed(2)}km<sup>2</sup>"

communityCirclesUtil = angular.module("communityCirclesUtil", [])
communityCirclesUtil.factory "Util", ->
  formatAreaHtml: (area) ->
    return "#{(area/1000).toFixed(2)}km<sup>2</sup>"
    