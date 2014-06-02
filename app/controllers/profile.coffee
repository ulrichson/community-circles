profileApp = angular.module "profileApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/profile/index.html
#------------------------------------------------------------------------------- 
profileApp.controller "IndexCtrl", ($scope, Util, Log, Config, UI) ->
  $scope.message_id = "profileIndexCtrl"
  $scope.username = Util.userName()
  $scope.user_id = Util.userId()
  $scope.supportEmail = Config.SUPPORT_EMAIL
  $scope.version = Config.VERSION

  # ARGHH, nasty hack...but it seem's button events can occur more often
  # And then this would happen: login view is pushed, user logs in and returns
  # to profile page and this page will fire the button event again and logout
  # the user...or something like that.
  # BETTER SOLUTION: reset app state, whatsoever, on logout
  logoutTapped = false
  document.addEventListener "visibilitychange"
  , ->
    if document.hidden
      logoutTapped = false
  , false

  $scope.logout = ->
    if not logoutTapped
      logoutTapped = true
      Util.logout()

  $scope.settings = ->
    steroids.modal.show new steroids.views.WebView "/views/settings/index.html"

  $scope.imprint = ->
    steroids.modal.show new steroids.views.WebView "/views/imprint/index.html"

  $scope.setUserName = (username) ->
    $scope.username = username

  $scope.setUserId = (user_id) ->
    $scope.user_id = user_id

  Util.consume $scope
  UI.autoRestoreView
    backgroundColor: "#ffffff"
    tabBar: true