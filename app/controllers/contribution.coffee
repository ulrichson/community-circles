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
contributionApp.controller "IndexCtrl", ($scope, Util, Config, ContributionRestangular) ->
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
contributionApp.controller "ShowCtrl", ($scope, $filter, $location, $anchorScroll, Util, Config, Log, UI, ContributionRestangular) ->
  $scope.message_id = "showContributionController"
  $scope.contribution = {}
  $scope.comments = []
  $scope.baseUrl = Config.API_ENDPOINT

  scrollBottom = false

  $scope.loadContribution = (id) ->
    $scope.contribution.id = id
    # Log.d "Loading contribution with id #{id}"
    $scope.loading = true
    ContributionRestangular.all("contribution").getList(id: id).then (data) ->
      $scope.contribution = data[0]
      $scope.loading = false

      $scope.loadComments $scope.contribution.id

  $scope.loadComments = (id) ->
    $scope.loading = true
    ContributionRestangular.all("comment").getList(contribution: id).then (data) ->
      # Log.d JSON.stringify data
      $scope.comments = data
      $scope.loading = false

      $scope.$apply()

      if scrollBottom
        scrollBottom = false
        $location.hash "bottom"
        $anchorScroll()

        $scope.$apply()

    , (response) ->
      Log.e "Couldn't load comments (#{response.data.detail})"
      $scope.loading = false
      $scope.$apply()

  $scope.addComment = ->
    onPrompt = (results) ->
      if results.buttonIndex is 1
        if results.input1 isnt ""
          $scope.comment = results.input1
          $scope.sendComment()
        # $scope.$apply()
    navigator.notification.prompt new String(), onPrompt, "Enter comment", ["Send", "Cancel"], new String()

  $scope.sendComment = ->
    $scope.loading = true
    Log.d "User with id=#{Util.userId()} is sending a comment"
    ContributionRestangular.all("comment").post(
      author: Util.userId()
      content: $scope.comment
      contribution: $scope.contribution.id
    ).then (response) ->
      $scope.comment = ""
      scrollBottom = true
      $scope.loadContribution $scope.contribution.id
      # navigator.notification.alert  "Thanks, your comment was sent"
      # , ->
      #   $scope.loading = false
      #   $location.hash "bottom"
      #   $anchorScroll()
      #   $scope.$apply()
      # , "Comment sent"
    , (response) ->
      Log.e "Couldn't send comment (#{JSON.stringify response.data})"
      navigator.notification.alert  "Please try again later"
      , ->
        $scope.loading = false
        $scope.$apply()
      , "Couldn't upload comment"

  $scope.voteContribution = ->
    if not $scope.hasVotedForContribution()
      ContributionRestangular.all("votecontribution").post
        contribution: $scope.contribution.id
        creator: Util.userId()
      .then (response) ->
        # Log.d JSON.stringify response
        $scope.loadContribution $scope.contribution.id
        navigator.notification.alert new String(), null, "Thanks for voting"
    else
      navigator.notification.alert "...and removing votes isn't implemented yet ;)", null, "You have already voted"

  $scope.hasVotedForContribution = ->
    return _.contains $scope.contribution.votes, Util.userName()

  $scope.voteComment = (comment) ->
    if not $scope.hasVotedForComment comment
      ContributionRestangular.all("votecomment").post
        comment: comment.id
        creator: Util.userId()
      .then (response) ->
        # Log.d JSON.stringify response
        $scope.loadComments $scope.contribution.id
        navigator.notification.alert new String(), null, "Thanks for voting"
    else
      navigator.notification.alert "...and removing votes isn't implemented yet ;)", null, "You have already voted"

  $scope.hasVotedForComment = (comment) ->
    return _.contains comment.votes, Util.userName()

  # Save current contribution id to localStorage (edit.html gets it from there)
  # localStorage.setItem "currentContributionId", steroids.view.params.id

  Util.consume $scope
  UI.autoRestoreView()

#-------------------------------------------------------------------------------
# New: http://localhost/views/contribution/new.html
#------------------------------------------------------------------------------- 
contributionApp.controller "NewCtrl", ($scope, $http, Util, Log, Config, ContributionRestangular) ->
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
  $scope.imageFullPath = null

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
      fileName = "contribution_photo_#{Util.userName()}_#{new Date().getTime()}.png"

      window.resolveLocalFileSystemURI(
        targetDirURI
        (directory) ->
          file.moveTo directory, fileName, fileMoved, fileError
        fileError
      )

    # Store the moved file's URL into $scope.imageSrc
    fileMoved = (file) ->
      # localhost serves files from both steroids.app.userFilesPath and steroids.app.path
      # Log.d "File located at #{JSON.stringify file}"
      $scope.imageFullPath = file.fullPath
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

  $scope.create = ->
    $scope.$apply -> $scope.loading = true

    mood = null
    try
      mood = $scope.contribution.mood.name
    catch e
      mood = null
    
    ContributionRestangular.all("contribution").post(
      title: $scope.contribution.title
      type: $scope.contribution.type
      description: $scope.contribution.description
      mood: mood
      author: Util.userId()
      user:
        id: Util.userId()
        username: Util.userName()
      accuracy: window.localStorage.getItem "position.coords.accuracy"
      point: "POINT (#{Util.lastKnownPosition().lng} #{Util.lastKnownPosition().lat})"
      poi: $scope.contribution.poi
    ).then (response) ->

      Log.d "Contribution with id=#{response.id} was created"

      if $scope.imageSrc
        imageURI = $scope.imageSrc

        # Upload photo
        options = new FileUploadOptions()
        options.fileKey = "photo"
        options.fileName = imageURI.substr imageURI.lastIndexOf("/") + 1
        options.mimeType = "image/jpeg"

        params =
          creator: Util.userId()
          contribution: response.id

        options.params = params

        uploadSuccess = (response) ->
          navigator.notification.alert  "Thanks, your contribution was uploaded."
          , ->
            $scope.loading = false
            $scope.reset()
            $scope.$apply()
            Util.send "mapIndexCtrl", "locate"
            Util.return()
          , "Successfully uploaded"

        uploadError = (response) ->
          navigator.notification.alert  "Your contribution was uploaded without your photo.\nYou can add it later. #{JSON.stringify response}"
          , ->
            $scope.loading = false
            $scope.reset()
            $scope.$apply()
            Util.return()
          , "Photo missing"

        # Log.d "#{imageURI}: #{JSON.stringify options}"

        ft = new FileTransfer()
        ft.upload $scope.imageFullPath, encodeURI("#{Config.API_ENDPOINT}/photo/"), uploadSuccess, uploadError, options
      else
        navigator.notification.alert  "Thanks, your contribution was uploaded."
        , ->
          $scope.loading = false
          $scope.reset()
          $scope.$apply()
          Util.return()
        , "Successfully uploaded"
    , (response) ->
      Log.e "Contribution upload failed: #{JSON.stringify response.data}"
      navigator.notification.alert  "Sorry, couldn't upload your contribution. Please try again later."
      , ->
        $scope.loading = false
        $scope.$apply()
      , "Failed to upload"

  $scope.setPoi = (poi) ->
    $scope.contribution.poi = poi

  $scope.setMood = (mood) ->
    $scope.contribution.mood = mood
    Log.d $scope.contribution.mood.name

  $scope.reset = ->
    $scope.contribution = {}
    $scope.contribution.type = null
    $scope.contribution.pollOptions = []
    $scope.removePhoto()

    Util.send "moodIndexCtrl", "reset"
    Util.send "poiIndexCtrl", "reset"

    $scope.hasError = false
    window.scrollTo 0, 0

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
      $scope.create()

  buttonAdd.onTap = ->
    error = false

    # Check form
    error = not $scope.contribution.type or
    not $scope.contribution.title or
    ($scope.contribution.type is "PL" and $scope.contribution.pollOptions.length < 2) or
    ($scope.contribution.type isnt "PL" and not $scope.contribution.description)

    if error
      alertCallback = ->
        $scope.hasError = true
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
        $scope.create()

  #-----------------------------------------------------------------------------
  # INIT
  #-----------------------------------------------------------------------------
  document.addEventListener "visibilitychange", onVisibilityChange, false

  Util.consume $scope

  steroids.view.setBackgroundColor "#ffffff"

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