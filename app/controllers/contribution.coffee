contributionApp = angular.module("contributionApp", ["communityCirclesApp", "ContributionModel", "hmTouchevents"]) 

#-------------------------------------------------------------------------------
# New: http://localhost/views/contribution/new.html
#------------------------------------------------------------------------------- 
contributionApp.controller "NewCtrl", ($scope, ContributionRestangular) ->
  $scope.loading = false
  $scope.bgImageStyle = {}

  #-----------------------------------------------------------------------------
  # CONTRIBUTION PROPERTIES
  #-----------------------------------------------------------------------------
  $scope.contribution = {}
  $scope.contribution.poi = null
  $scope.contribution.type = null
  $scope.contribution.mood = null

  #-----------------------------------------------------------------------------
  # CAMERA HANDLNG
  #-----------------------------------------------------------------------------
  $scope.imageSrc = null

  # Camera failure callback
  cameraError = (message) ->
    debug.warn "Capturing the photo failed: #{message}"
    $scope.$apply -> $scope.loading = false

  # File system failure callback
  fileError = (error) ->
    debug.warn "File system error: #{error}"
    $scope.$apply -> $scope.loading = false

  # Move the selected photo from Cordova's default tmp folder to Steroids's user files folder
  imageUriReceived = (imageURI) ->
    window.resolveLocalFileSystemURI imageURI, gotFileObject, fileError

  gotFileObject = (file) ->
    # Define a target directory for our file in the user files folder
    # steroids.app variables require the Steroids ready event to be fired, so ensure that
    steroids.on "ready", ->
      targetDirURI = "file://" + steroids.app.absoluteUserFilesPath
      fileName = "contribution_photo.png"

      window.resolveLocalFileSystemURI(
        targetDirURI
        (directory) ->
          file.moveTo directory, fileName, fileMoved, fileError
        fileError
      )

    # Store the moved file's URL into $scope.imageSrc
    fileMoved = (file) ->
      # localhost serves files from both steroids.app.userFilesPath and steroids.app.path
      $scope.imageSrc = "/" + file.name
      $scope.bgImageStyle = {
        "background-image": "url(#{$scope.imageSrc})"
      }
      $scope.$apply -> $scope.loading = false

  #-----------------------------------------------------------------------------
  # UI CALLBACKS
  #-----------------------------------------------------------------------------
  $scope.choosePhoto = ->
    navigator.notification.confirm null,
      (buttonIndex) ->
        return if buttonIndex is 3
        options = {}
        if buttonIndex is 1
          options =
            quality: 70
            destinationType: navigator.camera.DestinationType.IMAGE_URI
            sourceType: navigator.camera.PictureSourceType.PHOTOLIBRARY
            correctOrientation: true # Let Cordova correct the picture orientation (WebViews don't read EXIF data properly)
            targetWidth: 640
            popoverOptions: # iPad camera roll popover position
              width: 768
              height: 190
              arrowDir: Camera.PopoverArrowDirection.ARROW_UP
        else if buttonIndex is 2
          options =
            quality: 70
            destinationType: navigator.camera.DestinationType.IMAGE_URI
            correctOrientation: true
            targetWidth: 640
        navigator.camera.getPicture imageUriReceived, cameraError, options
        $scope.$apply -> $scope.loading = true
      "Which photo should be added?",
      ["From library", "Capture photo", "Cancel"]

  $scope.removePhoto = ->
    $scope.imageSrc = null

  $scope.chooseMood = ->
    moodWebView = new steroids.views.WebView "/views/mood/index.html"
    if $scope.contribution.mood isnt null
      moodWebView.location += "?mood=#{$scope.contribution.mood}" 
    steroids.layers.push moodWebView

  $scope.choosePoi = ->
    poiWebView = new steroids.views.WebView "/views/poi/index.html"
    if $scope.contribution.poi isnt null
      poiWebView.location += "?poi=#{$scope.contribution.poi}"
    steroids.layers.push poiWebView

  $scope.close = ->
    steroids.layers.pop()

  $scope.create = (contribution) ->
    $scope.$apply -> $scope.loading = true

    ContributionRestangular.all("contribution").post(contribution).then ->

      # Broadcast reload message
      msg = 
        status: "reload"

      window.postMessage msg, "*"

      $scope.pop()
      $scope.$apply -> $scope.loading = false
    , ->
      $scope.$apply -> $scope.loading = false
      alert("Sorry, couldn't upload your contribution. Please try again later");

  #-----------------------------------------------------------------------------
  # WINDOW MESSAGES
  #-----------------------------------------------------------------------------
  messageReceived = (event) ->
    if event.data.recipient is "contributionView"
      $scope.$apply -> 
        $scope.contribution.mood = event.data.mood if event.data.mood?
        $scope.contribution.poi = event.data.poi if event.data.poi?

  window.addEventListener "message", messageReceived

  #-----------------------------------------------------------------------------
  # CUSTOM NATIVE UI BAHAVIOR
  #-----------------------------------------------------------------------------
  # TODO: on back show confirmation dialog, if data was set 