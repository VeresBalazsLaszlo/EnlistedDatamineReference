import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *



let lookAtZone = mkEcsComputed({
  comps = [
    ["human__lookAtZoneQuickchat", ecs.TYPE_EID],
    ["human__lookAtZoneQuickchatTitle", ecs.TYPE_STRING],
    ["human__lookAtZoneQuickchatCanBeAttacked", ecs.TYPE_BOOL],
    ["human__lookAtZoneQuickchatCanBeDefended", ecs.TYPE_BOOL],
  ]
  comps_rq = ["hero"]
})

let zoneTitle = Computed(@() lookAtZone.get()?.human__lookAtZoneQuickchatTitle ?? "")
let zoneCanBeAttacked = Computed(@() lookAtZone.get()?.human__lookAtZoneQuickchatCanBeAttacked ?? false)
let zoneCanBeDefended = Computed(@() lookAtZone.get()?.human__lookAtZoneQuickchatCanBeDefended ?? false)

return {
  zoneTitle,
  zoneCanBeAttacked,
  zoneCanBeDefended
}
