moodApp = angular.module "moodApp", ["communityCirclesUtil", "MoodModel", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, Util, MoodRestangular) ->
  $scope.message_id = "moodIndexCtrl"

  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()

  $scope.choose = (mood) ->
    $scope.selectedMood = mood
    Util.send "contributionNewCtrl", "setMood", mood
    Util.return()

  $scope.reset = ->
    $scope.selectedMood = null

  Util.consume $scope