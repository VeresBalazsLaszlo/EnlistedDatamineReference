import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/ui_library.nut" import *

let grenadeItems = mkEcsComputedEidMap({
  comps = [
    ["item__grenadeType", ecs.TYPE_STRING],
    ["item__grenadeLikeType", ecs.TYPE_STRING, null],
  ]
  comps_rq = ["watchedPlayerItem"]
  comps_no = ["gun__hideInUi"]
})

let grenadesEids = Computed(function() {
  let res = {}
  foreach (eid, item in grenadeItems.get()) {
    let gType = item.item__grenadeType
    let glType = item.item__grenadeLikeType
    if (gType == "shell" && glType == null)
      continue
    res[eid] <- gType ?? glType
  }
  return res
})

let grenades = Computed(function(){
  let grenadesByType = {}
  let gEids = grenadesEids.get()
  foreach(gType in gEids) {
    grenadesByType[gType] <- (grenadesByType?[gType] ?? 0) + 1
  }
  return grenadesByType
})

return {
  grenades
  grenadesEids
}
