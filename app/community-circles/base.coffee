communityCirclesApp = angular.module("communityCirclesApp", [])

#-------------------------------------------------------------------------------
# APP INITIALIZATIOM
#-------------------------------------------------------------------------------
communityCirclesApp.run ->
  # Login
  steroids.modal.show new steroids.views.WebView "/views/login/index.html" unless window.localStorage.getItem("loggedIn") is "true"
  
  # Native UI
  steroids.view.navigationBar.show "Community Circles"

  buttonNotifications = new steroids.buttons.NavigationBarButton
  # buttonNotifications.title = "Notifications"
  buttonNotifications.imagePath = "/icons/mail@2x.png"
  buttonNotifications.onTap = ->
    steroids.modal.show new steroids.views.WebView "/views/notification/index.html"

  steroids.view.navigationBar.setButtons
    right: [buttonNotifications]

#-------------------------------------------------------------------------------
# APP PROPERTIES AND METHODS
#-------------------------------------------------------------------------------
communityCirclesApp.value "app",
  mapId: "ulrichson.he818hcj",
  mapInitZoom: 14,
  mapShowZoomControls: true,
  apiBaseUrl: "http://community-circles.ftw.at/api"
  test: ->
    alert "test message from app"
  logout: ->
    window.localStorage.setItem "loggedIn", false
    steroids.modal.show new steroids.views.WebView "/views/login/index.html"
  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"