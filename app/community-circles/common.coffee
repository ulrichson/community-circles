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
# Run
#-------------------------------------------------------------------------------
common.run (Log) ->
  if !@config? or !@key?
    alert "app/community-circles/private.coffee is missing or malformed!"

  # Only allow portrait mode
  steroids.view.setAllowedRotations [0, 180]
  steroids.view.setBackgroundColor "#ffffff"

#-------------------------------------------------------------------------------
# Constants
#------------------------------------------------------------------------------- 
common.constant "Config",
  SUPPORT_EMAIL: @config.SUPPORT_EMAIL
  API_ENDPOINT: @config.API_ENDPOINT
  REGEX_USERNAME: /^[a-zA-Z0-9\-\_\.]+$/
  VERSION: "v1.6.2"

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
      Log.d "remove"
      angular.element(wrapper).remove()

#-------------------------------------------------------------------------------
# Translate
#-------------------------------------------------------------------------------
common.factory "T", (gettextCatalog) ->
  _: (str) ->
    return gettextCatalog.getString str
#-------------------------------------------------------------------------------
# Session
#-------------------------------------------------------------------------------
common.factory "Session", (Log) ->
  login: (username, userId) ->
    window.localStorage.setItem "loggedIn", "true"
    window.localStorage.setItem "login.username", username
    window.localStorage.setItem "login.user_id", userId

    Log.i "User #{username} with id=#{userId} logged in (localStorage: login.user_id=#{window.localStorage.getItem "login.user_id"}, login.username=#{window.localStorage.getItem "login.username"})"

  logout: ->
    userId = window.localStorage.getItem "login.user_id"
    username = window.localStorage.getItem "login.username"

    window.localStorage.setItem "loggedIn", "false"
    window.localStorage.removeItem "login.username"
    window.localStorage.removeItem "login.user_id"

    Log.i "User #{username} with id=#{userId} logged out (localStorage: login.user_id=#{window.localStorage.getItem "login.user_id"}, login.username=#{window.localStorage.getItem "login.username"})"

  userId: ->
    return window.localStorage.getItem "login.user_id"

  userName: ->
    return window.localStorage.getItem "login.username"

  loggedIn: ->
    return window.localStorage.getItem("loggedIn") is "true"