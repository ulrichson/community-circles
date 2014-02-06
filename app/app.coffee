#-------------------------------------------------------------------------------
# GLOBAL VARIABLES
#-------------------------------------------------------------------------------
window.localStorage.setItem "rootWebView", steroids.view.location
window.localStorage.setItem "mainMenuVisible", "hidden"

#-----------------------------------------------------------------------------
# INITIALIZE NAVIGATION BAR
#----------------------------------------------------------------------------- 
steroids.view.navigationBar.show "Community Circles"

buttonMainMenu = new steroids.buttons.NavigationBarButton
buttonMainMenu.title = "Menu"
buttonMainMenu.onTap = ->
  toggleMainMenu()

buttonNotifications = new steroids.buttons.NavigationBarButton
buttonNotifications.title = "Notifications"
buttonNotifications.onTap = ->
  alert "Not done yet."

steroids.view.navigationBar.setButtons
  left: [buttonMainMenu]
  right: [buttonNotifications]

#-------------------------------------------------------------------------------
# INITIALIZE MAIN MENU (DRAWER)
#-------------------------------------------------------------------------------
mainMenuWebView = new steroids.views.WebView
  location: "/views/mainMenu/index.html"
  id: "mainMenu"

mainMenuWebView.preload {},
  onSuccess: ->
    # alert "menu loaded"
    # steroids.drawers.enableGesture mainMenuWebView if steroids.view.location.indexOf("map/index.html") is -1
  # onFailure: ->
  #   alert "error loading menu"

#-------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------
toggleMainMenu = ->
  # alert "mainMenuVisible=#{window.localStorage.getItem 'mainMenuVisible'}"
  if window.localStorage.getItem("mainMenuVisible") is "visible"
    # alert "close"
    window.localStorage.setItem "mainMenuVisible", "hidden"
    steroids.drawers.hide mainMenuWebView
  else
    # alert "show"
    window.localStorage.setItem "mainMenuVisible", "visible"
    steroids.drawers.show mainMenuWebView


