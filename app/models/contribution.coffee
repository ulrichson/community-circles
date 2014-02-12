# The contents of individual model .js files will be concatenated into dist/models.js

# Protects views where angular is not loaded from errors
if !angular?
  return

module = angular.module "ContributionModel", ["communityCirclesApp", "restangular"]

module.factory "ContributionRestangular", (Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->

# -- Stackmob REST API configuration

#    RestangularConfigurer.setBaseUrl('http:#api.stackmob.com');
#    RestangularConfigurer.setRestangularFields({
#      id: "contribution_id"
#    });

#    RestangularConfigurer.setDefaultHeaders({
#      'Accept': 'application/vnd.stackmob+json; version=0',
#      'X-StackMob-API-Key-<YOUR-API-KEY-HERE>': '1'
#    });
