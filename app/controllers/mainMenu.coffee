mainMenuApp = angular.module("mainMenuApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mainMenu/index.html
#------------------------------------------------------------------------------- 
mainMenuApp.controller "IndexCtrl", ($scope) -> 
  $scope.open = (location) ->
    # steroids.layers.popAll()
    # steroids.layers.push new steroids.views.WebView location

    # alert "#{webViewName steroids.view.location}"
    # alert "#{window.localStorage.getItem 'rootWebView'}"
    # alert "#{steroids.config.location}"

    rootWebView = webViewName window.localStorage.getItem "rootWebView"
    newWebView = new steroids.views.WebView location

    # alert "rootWebView=#{rootWebView}\nnewWebView=#{location}"

    if location in [rootWebView]
      steroids.drawers.hideAll()
    else
      newWebView.preload {},
        onSuccess: ->
          steroids.layers.replace newWebView
          steroids.drawers.hideAll()
          
  $scope.logout = ->
    $scope.open "/views/login/index.html"

  webViewName = (location) ->
    idx = "http://localhost/".length - 1
    return location.substring idx, location.length