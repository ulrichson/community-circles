moodApp = angular.module "moodApp", [
  "communityCirclesUtil",
  "communityCirclesLog",
  "MoodModel",
  "ngTouch"
]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/mood/index.html
#------------------------------------------------------------------------------- 
moodApp.controller "IndexCtrl", ($scope, $location, $anchorScroll, Util, UI, MoodRestangular) ->
  
  $scope.message_id = "moodIndexCtrl"

  MoodRestangular.all("mood").getList().then (moods) ->
    $scope.moods = moods

    # Scroll to selected element
    $location.hash $scope.selectedMood
    $anchorScroll()

  visibilityChanged = ->
    return

  selectMood = (mood) ->
    Util.send "contributionNewCtrl", "setMood", mood
    $scope.selectedMood = mood.code

  unselectMood = ->
    Util.send "contributionNewCtrl", "resetMood"
    $scope.selectedMood = null

  $scope.choose = (mood) ->
    if $scope.selectedMood? and $scope.selectedMood is mood.code
      unselectMood()
    else
      selectMood mood

  $scope.reset = ->
    unselectMood()
    window.scrollTo 0, 0

  $scope.unselect = ->
    unselectMood()

  Util.consume $scope
  document.addEventListener "visibilitychange", visibilityChanged, false

  UI.autoRestoreView()