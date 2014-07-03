mainApp = angular.module "mainApp", [
  "ionic",
  "common",
  "AccountModel",
  "NotificationModel",
  "angularMoment",
  "gettext"
]

mainApp.run (amMoment, gettextCatalog) ->
  language = "de"

  if language isnt "en"
    gettextCatalog.currentLanguage = language
    gettextCatalog.debug = true
    amMoment.changeLanguage language

#-------------------------------------------------------------------------------
# Routes
#------------------------------------------------------------------------------- 
mainApp.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "login",
    url: "/login"
    templateUrl: "login.html"
    controller: "LoginCtrl"
  .state "navigation",
    url: "/navigation"
    abstract: true
    templateUrl: "navigation-menu.html"
  .state "navigation.home",
    url: "/home"
    views:
      menuContent:
        templateUrl: "home.html"
  .state "navigation.browse-contributions",
    url: "/browse-contributions"
    views:
      menuContent:
        templateUrl: "browse-contributions.html"
        controller: "BrowseContributionsCtrl"
  .state "navigation.notifications",
    url: "/notifications"
    views:
      menuContent:
        templateUrl: "notifications.html"
        controller: "NotificationCtrl"

  $urlRouterProvider.otherwise "/login"

#-------------------------------------------------------------------------------
# MainCtrl
#-------------------------------------------------------------------------------
mainApp.controller "MainCtrl", ($scope, $state, $ionicSideMenuDelegate, Session) ->
  $scope.toggleLeft = ->
    $ionicSideMenuDelegate.toggleLeft()

  $scope.logout = ->
    Session.logout()
    $state.go "login"

#-------------------------------------------------------------------------------
# LoginCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "LoginCtrl", ($scope, $http, $state, gettext, T, $ionicLoading, $ionicPopup, Session, Config, AccountRestangular) ->
  $scope.loginVisible = true
  $scope.login = {}
  $scope.register = {}

  $scope.login = ->
    if not $scope.login.username? or not $scope.login.password?
      $ionicPopup.alert
        title: T._ gettext "Cannot login"
        template: T._ gettext "Please enter your crededentials!"
      return

    $ionicLoading.show
      template: T._ gettext "Logging in..."

    $scope.requesting = true

    credentials = btoa "#{$scope.login.username}:#{$scope.login.password}"
    $http
      url: "#{Config.API_ENDPOINT}/accounts/users/"
      method: "GET"
      headers:
        "Authorization": "Basic #{credentials}"
    .success (data) ->
      Session.login data.results[0].username, data.results[0].id
      $scope.reset()
      $ionicLoading.hide()
      $state.go "navigation.notifications", {}, { reload: true }
    .error (data) ->
      $ionicPopup.alert
        title: T._ gettext "An error occured"
        template: data.detail
      $scope.requesting = false
      $ionicLoading.hide()

  $scope.register = ->
    if not $scope.register.username or not $scope.register.email or not $scope.register.password
      $ionicPopup.alert 
        title: T._ gettext "You are not done yet"
        template: T._ gettext "Please enter all details!"
      return

    if not $scope.register.username.match Config.REGEX_USERNAME
      $ionicPopup.alert 
        title: T._ gettext "Your username is invalid"
        template: T._ gettext "It may contain letters, numbers, the characters '-', '_' and '.' but no special characters."
      return

    $ionicLoading.show
      template: T._ gettext "Registering account..."

    $scope.requesting = true

    AccountRestangular.all("register").post
      username: $scope.register.username
      email: $scope.register.email
      password: $scope.register.password
    .then (response) ->
      Session.login response.username, response.id
      $scope.reset()
      $ionicLoading.hide()
      $state.go "navigation.notifications", {}, { reload: true }
    , (response) ->
      $scope.requesting = false
      $ionicLoading.hide()
      title = T._ gettext "Sorry, an error occured"
      msg = T._ gettext "Please try again later."

      if response.hasOwnProperty "data"
        if response.data.hasOwnProperty "password"
          title = T._ gettext "Error with password"
          msg = response.data.password

        if response.data.hasOwnProperty "email"
          title = T._ gettext "Error with email"
          msg = response.data.email

        if response.data.hasOwnProperty "username"
          title = T._ gettext "Error with username"
          msg = response.data.username

      $ionicPopup.alert
        title: title
        template: msg

  $scope.switchView = ->
    if $scope.loginVisible
      $scope.loginVisible = false
    else
      $scope.loginVisible = true

  $scope.reset = ->
    $scope.loginVisible = true
    $scope.login.username = null
    $scope.login.password = null
    $scope.register.username = null
    $scope.register.email = null
    $scope.register.password = null
    $scope.requesting = false

#-------------------------------------------------------------------------------
# BrowseContributionsCtrl
#------------------------------------------------------------------------------- 
mainApp.controller "BrowseContributionsCtrl", ($scope) ->
  return

#-------------------------------------------------------------------------------
# NotificationCtrl
#-------------------------------------------------------------------------------
mainApp.controller "NotificationCtrl", ($scope, Session, NotificationRestangular) ->
  $scope.notifications = []

  $scope.loadNotifications = ->
    NotificationRestangular.all("notifications").getList
      user: Session.userId()
    .then (data) ->
      $scope.notifications = data
    .finally ->
      $scope.$broadcast "scroll.refreshComplete"

  $scope.openContribution = (contribution) ->
    return

  # Init
  $scope.loadNotifications()
