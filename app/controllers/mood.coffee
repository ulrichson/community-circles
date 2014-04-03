moodApp = angular.module "moodApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "MoodModel",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, Util, MoodRestangular) ->
  
  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()

  visibilityChanged = ->
    return

  selectMood = (mood) ->
    Util.send "contributionNewCtrl", "setMood", mood.name
    $scope.selectedMood = mood.code

  unselectMood = ->
    Util.send "contributionNewCtrl", "setMood", null
    $scope.selectedMood = null
    return

  $scope.choose = (mood) ->
    if $scope.selectedMood? and $scope.selectedMood is mood.code
      unselectMood()
    else
      selectMood mood

  document.addEventListener "visibilitychange", visibilityChanged, false