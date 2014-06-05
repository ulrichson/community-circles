notificationApp = angular.module "notificationApp", [
  "communityCirclesUtil",
  "NotificationModel",
  "ngTouch",
  "angularMoment"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/notification/index.html
#------------------------------------------------------------------------------- 
notificationApp.controller "IndexCtrl", ($scope, Util, Log, UI, NotificationRestangular) ->
  $scope.notifications = []

  $scope.loadNotifications = ->
    NotificationRestangular.all("notifications").getList
      user: Util.userId()
    .then (data) ->
      console.log data
      $scope.notifications = data

  $scope.openContribution = (contribution) ->
    Util.send "showContributionController", "loadContribution", contribution
    Util.enter "showContributionView",
      tabBar: false

  # Run
  $scope.loadNotifications()
  UI.autoRestoreView
    backgroundColor: "#ffffff"
    tabBar: true

  document.addEventListener "visibilitychange"
  , ->
    $scope.loadNotifications()
  , false