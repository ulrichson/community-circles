communityCirclesUtil = angular.module "communityCirclesLog", []

communityCirclesUtil.factory "Log", ->
  w: (msg) ->
    console.warn msg
    steroids.logger.log "WARN - #{msg}"
  d: (msg) ->
    console.debug msg
    steroids.logger.log "DEBUG - #{msg}"
  i: (msg) ->
    console.log msg
    steroids.logger.log "INFO - #{msg}"
  e: (msg) ->
    console.error msg
    steroids.logger.log "ERROR - #{msg}"