var carApp = angular.module('carApp', ['CarModel', 'hmTouchevents']);


// Index: http://localhost/views/car/index.html

carApp.controller('IndexCtrl', function ($scope, CarRestangular) {

  // Helper function for opening new webviews
  $scope.open = function(id) {
    webView = new steroids.views.WebView("/views/car/show.html?id="+id);
    steroids.layers.push(webView);
  };

  // Fetch all objects from the local JSON (see app/models/car.js)
  $scope.cars = CarRestangular.all('car').getList();

  // -- Native navigation
  steroids.view.navigationBar.show("Car index");

});


// Show: http://localhost/views/car/show.html?id=<id>

carApp.controller('ShowCtrl', function ($scope, $filter, CarRestangular) {

  // Fetch all objects from the local JSON (see app/models/car.js)
  CarRestangular.all('car').getList().then( function(cars) {
    // Then select the one based on the view's id query parameter
    $scope.car = $filter('filter')(cars, {car_id: steroids.view.params['id']})[0];
  });

  // -- Native navigation
  steroids.view.navigationBar.show("Car: " + steroids.view.params.id );

});
