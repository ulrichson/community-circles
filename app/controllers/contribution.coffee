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

  #-----------------------------------------------------------------------------
  # WINDOW MESSAGES
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  # CUSTOM NATIVE UI BAHAVIOR
  #-----------------------------------------------------------------------------
  # TODO: on back show confirmation dialog, if data was set 

  #-----------------------------------------------------------------------------
  # RUN
  #-----------------------------------------------------------------------------
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