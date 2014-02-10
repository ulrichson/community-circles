moodApp = angular.module("moodApp", ["hmTouchevents"])

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope) ->
  $scope.mood = steroids.view.params.mood
  $scope.choose = (mood) ->
    window.postMessage
      recipient: "contributionView"
      mood: mood
    steroids.layers.pop()