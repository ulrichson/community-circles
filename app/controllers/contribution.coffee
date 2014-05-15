contributionApp = angular.module "contributionApp", [
  "communityCirclesApp",
  "communityCirclesUtil",
  "communityCirclesLog",
  "ContributionModel",
  "ngTouch",
  "angularMoment",
  "angular-carousel"
] 

#-------------------------------------------------------------------------------
# Index: http://localhost/views/contribution/index.html
#------------------------------------------------------------------------------- 
contributionApp.controller "IndexCtrl", ($scope, Util, ContributionRestangular) ->
  $scope.contributions = []

  $scope.open = (id) ->
    Util.send "showContributionController", "loadContribution", id
    webView = new steroids.views.WebView 
      location: "/views/contribution/show.html"
      id: "showContributionView"
    steroids.layers.push webView

  $scope.loadContributions = ->
    $scope.loading = true
    contributions.getList().then (data) ->
      $scope.length = data.length
      $scope.contributions = data
      $scope.loading = false

  contributions = ContributionRestangular.all "contribution"
  $scope.loadContributions()

  window.addEventListener "message", (event) ->
    if event.data.status is "reload" 
      $scope.loadContributions()

  showContributionView = new steroids.views.WebView 
    location: "/views/contribution/show.html"
    id: "showContributionView"
  showContributionView.preload()

#-------------------------------------------------------------------------------
# Show: http://localhost/views/contribution/show.html?id=<id>
#------------------------------------------------------------------------------- 
contributionApp.controller "ShowCtrl", ($scope, $filter, Util, ContributionRestangular) ->
  $scope.message_id = "showContributionController"

  $scope.loadContribution = (id) ->
    $scope.loading = true
    contributions.getList().then (data) ->
      $scope.contribution = $filter("filter")(data, {id: id})[0]

      # Simple demo data
      $scope.comments = [
        creator: "ulrichson"
        created: new Date()
        text: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et"
      ,
        creator: "ulrichson"
        created: new Date()
        text: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et"
      ,
        creator: "ulrichson"
        created: new Date()
        text: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et"
      ]

      $scope.loading = false

  # Save current contribution id to localStorage (edit.html gets it from there)
  # localStorage.setItem "currentContributionId", steroids.view.params.id

  contributions = ContributionRestangular.all "contribution"
  Util.consume $scope

#-------------------------------------------------------------------------------
# New: http://localhost/views/contribution/new.html
#------------------------------------------------------------------------------- 
contributionApp.controller "NewCtrl", ($scope, Util, Log, ContributionRestangular) ->
  $scope.message_id = "contributionNewCtrl"

  $scope.loading = false
  $scope.bgImageStyle = {}
  $scope.hasError = false

  #-----------------------------------------------------------------------------
  # CONTRIBUTION PROPERTIES
  #-----------------------------------------------------------------------------
  $scope.contribution = {}
  $scope.contribution.poi = null
  $scope.contribution.type = null
  $scope.contribution.mood = null
  $scope.contribution.pollOptions = []

  #-----------------------------------------------------------------------------
  # CAMERA HANDLNG
  #-----------------------------------------------------------------------------
  $scope.imageSrc = null

  # Camera failure callback
  cameraError = (message) ->
    Log.w "Capturing the photo failed: #{message}"
    $scope.$apply -> $scope.loading = false

  # File system failure callback
  fileError = (error) ->
    Log.w "File system error: #{error}"
    $scope.$apply -> $scope.loading = false

  # Move the selected photo from Cordova's default tmp folder to Steroids's user files folder
  imageUriReceived = (imageURI) ->
    window.resolveLocalFileSystemURI imageURI, gotFileObject, fileError

  gotFileObject = (file) ->
    # Define a target directory for our file in the user files folder
    # steroids.app variables require the Steroids ready event to be fired, so ensure that
    steroids.on "ready", ->
      targetDirURI = "file://" + steroids.app.absoluteUserFilesPath
      fileName = "contribution_photo_#{new Date().getTime()}.png"

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
  $scope.addPollOption = ->
    # alert $scope.contribution.pollOption
    $scope.contribution.pollOptions.push $scope.contribution.pollOption
    $scope.contribution.pollOption = ""

  $scope.addPollOptionPrompt = ->
    onPrompt = (results) ->
      if results.buttonIndex is 1
        $scope.contribution.pollOptions.push results.input1 if results.input1 isnt ""
        $scope.$apply()
    navigator.notification.prompt "Please enter in the field below.", onPrompt, "Add poll option", ["Add", "Cancel"], new String()

  $scope.removePollOption = (pollOption) ->
    $scope.contribution.pollOptions = _.without $scope.contribution.pollOptions, pollOption

  $scope.choosePhoto = (msg) ->
    navigator.notification.confirm "Select source below",
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
      msg,
      ["From library", "Capture photo", "Cancel"]

  $scope.removePhoto = ->
    $scope.imageSrc = null
    $scope.bgImageStyle = {}

  $scope.chooseMood = ->
    Util.enter "moodView"

  $scope.choosePoi = ->
    Util.enter "poiView"

  $scope.close = ->
    Util.return()

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
      alert "Sorry, couldn't upload your contribution. Please try again later"

  $scope.setPoi = (poi) ->
    $scope.contribution.poi = poi

  $scope.setMood = (mood) ->
    $scope.contribution.mood = mood

  $scope.reset = ->
    $scope.contribution = {}
    $scope.contribution.poi = null
    $scope.contribution.type = null
    $scope.contribution.mood = null
    $scope.contribution.pollOptions = []
    $scope.removePhoto()
    $scope.hasError = false

  #-----------------------------------------------------------------------------
  # NATIVE UI
  #-----------------------------------------------------------------------------
  buttonAdd = new steroids.buttons.NavigationBarButton
  buttonAdd.title = "Add"

  #-----------------------------------------------------------------------------
  # EVENTS
  #-----------------------------------------------------------------------------
  onVisibilityChange = ->
    if !document.hidden
      steroids.view.navigationBar.setButtons
          right: [buttonAdd]

  onConfirm = (buttonIndex) ->
    if buttonIndex is 2
      return
    else if buttonIndex is 1
      alert "not implemented"

  buttonAdd.onTap = ->
    error = false

    # Check form
    error = not $scope.contribution.type or
    not $scope.contribution.title or
    ($scope.contribution.type is "poll" and $scope.contribution.pollOptions.length < 2) or
    ($scope.contribution.type isnt "poll" and not $scope.contribution.description)

    if error
      alertCallback = ->
        $scope.showError = true
        $scope.$apply()
      navigator.notification.alert "Oops, there's something missing!\nPlease check the comments below.", alertCallback, "Something is missing", "Got it!"
    else
      # Meta parameter incentive messages
      title = null
      msg = null
      if !$scope.imageSrc?
        error = true
        title = "Do you want to include a photo?"
        msg = "Adding a photo gives your contribution more meaning and increases your radius!"
      else if !$scope.contribution.poi? or !$scope.contribution.mood?
        error = true
        title = "Do you want to provide additional information?"
        missing = "your location and mood"
        if $scope.contribution.mood?
          missing = "your location"
        else if $scope.contribution.poi?
          missing = "your mood"

        msg = "Adding #{missing} gives your contribution more meaning and increases your radius!"

      if error
        navigator.notification.confirm msg, onConfirm, title, ["Proceed anyway", "Edit contribution"]
      else
        alert "not implemented"

  #-----------------------------------------------------------------------------
  # RUN
  #-----------------------------------------------------------------------------
  document.addEventListener "visibilitychange", onVisibilityChange, false

  Util.consume $scope

#-------------------------------------------------------------------------------
# Edit: http://localhost/views/contribution/edit.html
#------------------------------------------------------------------------------- 
# contributionApp.controller('EditCtrl', function ($scope, ContributionRestangular) {

#   var id  = localStorage.getItem("currentContributionId"),
#       contribution = ContributionRestangular.one("contribution", id);

#   $scope.close = function() {
#     steroids.modal.hide();
#   };

#   $scope.update = function(contribution) {
#     $scope.loading = true;

#     contribution.put().then(function() {

#       // Notify the show.html to reload data
#       var msg = { status: "reload" };
#       window.postMessage(msg, "*");

#       $scope.close();
#       $scope.loading = false;
#     }, function() {
#       $scope.loading = false;

#       alert("Error when editing the object, is Restangular configured correctly, are the permissions set correctly?");
#     });

#   };

#   // Helper function for loading contribution data with spinner
#   $scope.loadContribution = function() {
#     $scope.loading = true;

#     // Fetch a single object from the backend (see app/models/contribution.js)
#     contribution.get().then(function(data) {
#       $scope.contribution = data;
#       $scope.loading = false;
#     });
#   };

#   $scope.loadContribution();

# }); 