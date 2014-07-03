mainApp = angular.module "mainApp", [
  "ionic",
  "communityCirclesUtil",
  "NotificationModel",
  "angularMoment"
]

mainApp.config ($stateProvider, $urlRouterProvider) ->
  $stateProvider.state "eventmenu",
    url: "/event"
    abstract: true
    templateUrl: "event-menu.html"
  .state "eventmenu.home",
    url: "/home"
    views:
      menuContent:
        templateUrl: "home.html"
  .state "eventmenu.checkin",
    url: "/check-in"
    views:
      menuContent:
        templateUrl: "check-in.html"
        controller: "CheckinCtrl"
  .state "eventmenu.attendees",
    url: "/attendees"
    views:
      menuContent:
        templateUrl: "attendees.html"
        controller: "AttendeesCtrl"
  .state "eventmenu.browse-contributions",
    url: "/browse-contributions"
    views:
      menuContent:
        templateUrl: "browse-contributions.html"
        controller: "BrowseContributionsCtrl"
  .state "eventmenu.notifications",
    url: "/notifications"
    views:
      menuContent:
        templateUrl: "notifications.html"
        controller: "NotificationCtrl"

  $urlRouterProvider.otherwise "/event/home"

mainApp.controller "MainCtrl", ($scope, $ionicSideMenuDelegate) ->
  $scope.attendees = [
    {
      firstname: "Nicolas"
      lastname: "Cage"
    }
    {
      firstname: "Jean-Claude"
      lastname: "Van Damme"
    }
    {
      firstname: "Keanu"
      lastname: "Reeves"
    }
    {
      firstname: "Steven"
      lastname: "Seagal"
    }
  ]
  $scope.toggleLeft = ->
    $ionicSideMenuDelegate.toggleLeft()

mainApp.controller "CheckinCtrl", ($scope) ->
  $scope.showForm = true
  $scope.shirtSizes = [
    {
      text: "Large"
      value: "L"
    }
    {
      text: "Medium"
      value: "M"
    }
    {
      text: "Small"
      value: "S"
    }
  ]
  $scope.attendee = {}
  $scope.submit = ->
    unless $scope.attendee.firstname
      alert "Info required"
  
    $scope.showForm = false
    $scope.attendees.push $scope.attendee

mainApp.controller "AttendeesCtrl", ($scope) ->
  $scope.activity = []
  $scope.arrivedChange = (attendee) ->
    msg = attendee.firstname + " " + attendee.lastname
    msg += ((if not attendee.arrived then " has arrived, " else " just left, "))
    msg += new Date().getMilliseconds()
    $scope.activity.push msg
    $scope.activity.splice 0, 1  if $scope.activity.length > 3

mainApp.controller "BrowseContributionsCtrl", ($scope) ->
  return

mainApp.controller "NotificationCtrl", ($scope, Util, NotificationRestangular) ->
  $scope.notifications = []

  $scope.loadNotifications = ->
    NotificationRestangular.all("notifications").getList
      user: 3
    .then (data) ->
      $scope.notifications = data
    .finally ->
      $scope.$broadcast "scroll.refreshComplete"

  $scope.openContribution = (contribution) ->
    return

  # Run
  $scope.loadNotifications()
