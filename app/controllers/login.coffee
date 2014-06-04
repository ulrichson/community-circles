loginApp = angular.module "loginApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "AccountModel",
  "ngTouch",
  "ngAnimate"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/login/index.html
#------------------------------------------------------------------------------- 
loginApp.controller "IndexCtrl", ($scope, $http, Util, Log, Config, UI, AccountRestangular) ->
  $scope.loginVisible = true
  $scope.buttonText = "Register"

  $scope.login = {}
  $scope.register = {}

  $scope.login = ->
    if not $scope.login.username? or not $scope.login.password?
      UI.alert
        title: "Cannot login"
        message: "Please enter your crededentials!"
      return

    credentials = btoa "#{$scope.login.username}:#{$scope.login.password}"

    # AccountRestangular.all("users").getList {},
    #   "Authorization": "Basic #{credentials}"
    # .then (response) ->
    #   UI.alert message: "yess"
    # , (error) ->
    #   Log.d JSON.stringify error
    #   UI.alert message: error.data.detail

    $scope.requesting = true

    $http
      url: "#{Config.API_ENDPOINT}/accounts/users/"
      method: "GET"
      headers:
        "Authorization": "Basic #{credentials}"
    .success (data) ->
      Util.login data.results[0].username, data.results[0].id
      Util.send "profileIndexCtrl", "setUserName", data.results[0].username
      Util.send "profileIndexCtrl", "setUserId", data.results[0].id
      steroids.layers.popAll()
      $scope.reset()
      $scope.requesting = false
    .error (data) ->
      UI.alert message: data.detail
      $scope.requesting = false

  $scope.register = ->
    if not $scope.register.username or not $scope.register.email or not $scope.register.password
      UI.alert 
        title: "You are not done yet"
        message: "Please enter all details!"
      return

    if not $scope.register.username.match Config.REGEX_USERNAME
      UI.alert 
        title: "Your username is invalid"
        message: "It may contain letters, numbers, the characters '-', '_' and '.' but no special characters."
      return

    $scope.requesting = true
    AccountRestangular.all("register").post
      username: $scope.register.username
      email: $scope.register.email
      password: $scope.register.password
    .then (response) ->
      Log.d JSON.stringify response
      Util.login response.username, response.id
      Util.send "profileIndexCtrl", "setUserName", response.username
      Util.send "profileIndexCtrl", "setUserId", response.id
      steroids.layers.popAll()
      $scope.reset()
      $scope.requesting = false
    , (response) ->
      $scope.requesting = false
      # Log.e JSON.stringify response
      title = "Sorry, an error occured"
      msg = "Please try again later."

      # if response.hasOwnProperty "data"
      #   if response.data.hasOwnProperty "password"
      #     title = "Error with password"
      #     msg = response.data.password

      #   if response.data.hasOwnProperty "email"
      #     title = "Error with email"
      #     msg = response.data.email

      #   if response.data.hasOwnProperty "username"
      #     title = "Error with username"
      #     msg = response.data.username

      UI.alert
        title: title
        message: msg

  $scope.switchView = ->
    if $scope.loginVisible
      $scope.loginVisible = false
      $scope.buttonText = "Back to login"
    else
      $scope.loginVisible = true
      $scope.buttonText = "Register"

  $scope.reset = ->
    $scope.loginVisible = true
    $scope.login.username = null
    $scope.login.password = null
    $scope.register.username = null
    $scope.register.email = null
    $scope.register.password = null

  UI.autoRestoreView
    backgroundColor: "#00a8b3"
    navigationBar: false
