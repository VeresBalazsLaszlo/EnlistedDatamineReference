import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let respawnBases = mkEcsComputedEidMap({
  comps = [
    ["active", ecs.TYPE_BOOL],
    ["respawnbaseType", ecs.TYPE_STRING, ""],
    ["respawnbaseSubtype", ecs.TYPE_STRING, ""],
  ]
  comps_rq = ["vehicleRespbase"]
})

let vehicleRespawnBases = Computed(function() {
  let res = {}
  foreach (respawnbase in respawnBases.get()) {
    let { active, respawnbaseType, respawnbaseSubtype } = respawnbase
    local keysByType = res?[respawnbaseType]
    if (keysByType == null) {
      keysByType = {}
      res[respawnbaseType] <- keysByType
    }
    keysByType[respawnbaseSubtype] <- (keysByType?[respawnbaseSubtype] ?? false) || active
  }
  return res
})

return vehicleRespawnBases
