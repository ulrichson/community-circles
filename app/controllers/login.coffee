loginApp = angular.module("loginApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope) ->
  $scope.login = ->
    mapWebView = new steroids.views.WebView "/views/map/index.html"
    # mapWebView.preload {},
    #   onSuccess: ->
    #     alert "success"
    #     steroids.layers.replace
    #       view: mapWebView
    #     , onSuccess: ->
    #       alert "The layer has been replaced"
    #     , onError: (error) ->
    #       alert "Could not replace the layer stack: #{error.errorDescription}"
    # steroids.layers.push mapWebView
    mapWebView.preload {},
      onSuccess: ->
        steroids.layers.replace mapWebView