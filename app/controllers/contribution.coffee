contributionApp = angular.module("contributionApp", ["communityCirclesApp", "ContributionModel", "hmTouchevents"]) 

#-------------------------------------------------------------------------------
# New: http://localhost/views/contribution/new.html
#------------------------------------------------------------------------------- 
contributionApp.controller "NewCtrl", ($scope, ContributionRestangular) ->
  if window.location.href.indexOf("http://localhost") is 0
    console.warn "The project is being served from http://localhost/. Since Cordova's Camera API returns the location of the photo file as a file:// URL, trying to display the photo produces an error (due to the different protocols)."
  
  $scope.loading = false
  $scope.mood = "[Not selected]"

  imgElement = document.querySelector("#photo")
  photoURI = null

  showPhoto = ->
    imgElement.style.display = "block"

  hidePhoto = ->
    imgElement.style.display = "none"

  # Show the selected image
  imageURIReceived = (imageURI) ->
    console.debug "Received imageURI=#{imageURI}"
    imgElement.src = imageURI
    photoURI = imageURI
    showPhoto()

  # Camera failure callback
  cameraError = (message) ->
    console.log "Capturing the photo failed: #{message}"
    # showPhoto()

  $scope.capturePhoto = ->
    navigator.camera.getPicture imageURIReceived, cameraError,
      quality: 70
      destinationType: navigator.camera.DestinationType.IMAGE_URI
      correctOrientation: true
      targetWidth: 1000

  $scope.removePhoto = ->
    hidePhoto()
    photoURI = null

  $scope.chooseMood = ->
    moodWebView = new steroids.views.WebView "/views/mood/index.html"
    if $scope.mood isnt "[Not selected]"
      moodWebView.location += "?mood=#{$scope.mood}" 
    steroids.layers.push moodWebView

  $scope.close = ->
    steroids.layers.pop()

  $scope.create = (contribution) ->
    $scope.$apply -> $scope.loading = true

    # ContributionRestangular.all('contribution').post(contribution).then(function() {

    #   // Notify the index.html to reload
    #   var msg = { status: 'reload' };
    #   window.postMessage(msg, "*");

    #   $scope.close();
    #   $scope.loading = false;

    # }, function() {
    #   $scope.loading = false;

    #   alert("Error when creating the object, is Restangular configured correctly, are the permissions set correctly?");

    # });

  # $scope.contribution = {}
  # Inform the user that if the project is being served from localhost, the example doesn't function correctly
  messageReceived = (event) ->
    if event.data.recipient is "contributionView"
      $scope.$apply -> $scope.mood = event.data.mood

  window.addEventListener "message", messageReceived