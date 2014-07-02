mainApp = angular.module "mainApp", ["ionic"]

mainApp.controller "IndexCtrl", ($scope) ->
  $scope.message = "heyho world"