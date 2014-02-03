var contributionApp = angular.module('contributionApp', ['ContributionModel', 'hmTouchevents']);


// Index: http://localhost/views/contribution/index.html

contributionApp.controller('IndexCtrl', function ($scope, ContributionRestangular) {

  // This will be populated with Restangular
  $scope.contributions = [];

  // Helper function for opening new webviews
  $scope.open = function(id) {
    webView = new steroids.views.WebView("/views/contribution/show.html?id="+id);
    steroids.layers.push(webView);
  };

  // Helper function for loading contribution data with spinner
  $scope.loadContributions = function() {
    $scope.loading = true;

    contributions.getList().then(function(data) {
      $scope.contributions = data;
      $scope.loading = false;
    });

  };

  // Fetch all objects from the backend (see app/models/contribution.js)
  var contributions = ContributionRestangular.all('contribution');
  $scope.loadContributions();


  // Get notified when an another webview modifies the data and reload
  window.addEventListener("message", function(event) {
    // reload data on message with reload status
    if (event.data.status === "reload") {
      $scope.loadContributions();
    };
  });


  // -- Native navigation

  // Set navigation bar..
  steroids.view.navigationBar.show("Contribution index");

  // ..and add a button to it
  var addButton = new steroids.buttons.NavigationBarButton();
  addButton.title = "Add";

  // ..set callback for tap action
  addButton.onTap = function() {
    var addView = new steroids.views.WebView("/views/contribution/new.html");
    steroids.modal.show(addView);
  };

  // and finally put it to navigation bar
  steroids.view.navigationBar.setButtons({
    right: [addButton]
  });


});


// Show: http://localhost/views/contribution/show.html?id=<id>

contributionApp.controller('ShowCtrl', function ($scope, ContributionRestangular) {

  // Helper function for loading contribution data with spinner
  $scope.loadContribution = function() {
    $scope.loading = true;

     contribution.get().then(function(data) {
       $scope.contribution = data;
       $scope.loading = false;
    });

  };

  // Save current contribution id to localStorage (edit.html gets it from there)
  localStorage.setItem("currentContributionId", steroids.view.params.id);

  var contribution = ContributionRestangular.one("contribution", steroids.view.params.id);
  $scope.loadContribution()

  // When the data is modified in the edit.html, get notified and update (edit is on top of this view)
  window.addEventListener("message", function(event) {
    if (event.data.status === "reload") {
      $scope.loadContribution()
    };
  });

  // -- Native navigation
  steroids.view.navigationBar.show("Contribution: " + steroids.view.params.id );

  var editButton = new steroids.buttons.NavigationBarButton();
  editButton.title = "Edit";

  editButton.onTap = function() {
    webView = new steroids.views.WebView("/views/contribution/edit.html");
    steroids.modal.show(webView);
  }

  steroids.view.navigationBar.setButtons({
    right: [editButton]
  });


});


// New: http://localhost/views/contribution/new.html

contributionApp.controller('NewCtrl', function ($scope, ContributionRestangular) {

  $scope.close = function() {
    steroids.modal.hide();
  };

  $scope.create = function(contribution) {
    $scope.loading = true;

    ContributionRestangular.all('contribution').post(contribution).then(function() {

      // Notify the index.html to reload
      var msg = { status: 'reload' };
      window.postMessage(msg, "*");

      $scope.close();
      $scope.loading = false;

    }, function() {
      $scope.loading = false;

      alert("Error when creating the object, is Restangular configured correctly, are the permissions set correctly?");

    });

  }

  $scope.contribution = {};

});


// Edit: http://localhost/views/contribution/edit.html

contributionApp.controller('EditCtrl', function ($scope, ContributionRestangular) {

  var id  = localStorage.getItem("currentContributionId"),
      contribution = ContributionRestangular.one("contribution", id);

  $scope.close = function() {
    steroids.modal.hide();
  };

  $scope.update = function(contribution) {
    $scope.loading = true;

    contribution.put().then(function() {

      // Notify the show.html to reload data
      var msg = { status: "reload" };
      window.postMessage(msg, "*");

      $scope.close();
      $scope.loading = false;
    }, function() {
      $scope.loading = false;

      alert("Error when editing the object, is Restangular configured correctly, are the permissions set correctly?");
    });

  };

  // Helper function for loading contribution data with spinner
  $scope.loadContribution = function() {
    $scope.loading = true;

    // Fetch a single object from the backend (see app/models/contribution.js)
    contribution.get().then(function(data) {
      $scope.contribution = data;
      $scope.loading = false;
    });
  };

  $scope.loadContribution();

});