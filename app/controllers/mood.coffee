moodApp = angular.module("moodApp", ["MoodModel", "hmTouchEvents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, MoodRestangular) ->
  
  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods
    $scope.selectedMood = steroids.view.params.mood

  $scope.choose = (mood) ->
    window.postMessage
      recipient: "contributionView"
      mood: mood
    steroids.layers.pop()