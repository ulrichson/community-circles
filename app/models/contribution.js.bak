// The contents of individual model .js files will be concatenated into dist/models.js

(function() {

// Protects views where angular is not loaded from errors
if ( typeof angular == 'undefined' ) {
	return;
};


var module = angular.module('ContributionModel', ['restangular']);

module.factory('ContributionRestangular', function(Restangular) {

  // window.setTimeout(function() {
  //   alert("Good! Now configure app/models/contribution.js");
  // }, 2000);

  return Restangular.withConfig(function(RestangularConfigurer) {

// -- Stackmob REST API configuration

//    RestangularConfigurer.setBaseUrl('http://api.stackmob.com');
//    RestangularConfigurer.setRestangularFields({
//      id: "contribution_id"
//    });

//    RestangularConfigurer.setDefaultHeaders({
//      'Accept': 'application/vnd.stackmob+json; version=0',
//      'X-StackMob-API-Key-<YOUR-API-KEY-HERE>': '1'
//    });

  });

});


})();
