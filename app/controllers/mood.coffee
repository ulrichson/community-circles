moodApp = angular.module("moodApp", ["MoodModel", "hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, MoodRestangular) ->
  $scope.selectedMood = steroids.view.params.mood
  $scope.moods = MoodRestangular.all("mood").getList()

  $scope.choose = (mood) ->
    window.postMessage
      recipient: "contributionView"
      mood: mood
    steroids.layers.pop()