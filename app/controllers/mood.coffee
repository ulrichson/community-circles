moodApp = angular.module("moodApp", ["MoodModel", "ngTouch"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, MoodRestangular) ->
  
  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()

  $scope.choose = (mood) ->
    window.postMessage
      recipient: "contributionView"
      mood: mood
    $scope.selectedMood = mood
    steroids.layers.pop()

  window.addEventListener "message", (event) ->
    if event.data.recipient is "moodView"
      if event.data.command is "reset"
        $scope.$apply -> $scope.selectedMood = null