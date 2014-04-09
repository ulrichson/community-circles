imprintApp = angular.module "imprintApp", ["communityCirclesUtil", "ngTouch"]

#-------------------------------------------------------------------------------
# Index: http://localhost/views/imprint/index.html
#------------------------------------------------------------------------------- 
imprintApp.controller "IndexCtrl", ($scope, Util) ->
  $scope.close = ->
    steroids.modal.hide()