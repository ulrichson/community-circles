communityCirclesApp = angular.module "communityCirclesApp", []

#-------------------------------------------------------------------------------
# APP INITIALIZATIOM
#-------------------------------------------------------------------------------
# communityCirclesApp.run ->
#   if !@key?
#     alert "app/community-circles/keys.coffee is missing!"

  # Login
  # if window.localStorage.getItem("loggedIn") isnt "true"
  #   steroids.layers.push new steroids.views.WebView
  #     location: ""
  #     id: "loginView"
  # Native UI
  # steroids.view.navigationBar.show ""

  # buttonNotifications = new steroids.buttons.NavigationBarButton
  # buttonNotifications.imagePath = "/icons/mail@2x.png"
  # buttonNotifications.onTap = ->
  #   steroids.modal.show new steroids.views.WebView "/views/notification/index.html"

  # steroids.view.navigationBar.setButtons
  #   right: [buttonNotifications]

#-------------------------------------------------------------------------------
# APP PROPERTIES AND METHODS
#-------------------------------------------------------------------------------
communityCirclesApp.value "app",
  mapInitZoom: 14,
  mapShowZoomControls: true,
  apiBaseUrl: "http://community-circles.ftw.at/api"
  test: ->
    alert "test message from app"
  logout: ->
    alert "logout"
    window.localStorage.setItem "loggedIn", false
    steroids.layers.push new steroids.views.WebView
      location: ""
      id: "loginView"
  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"