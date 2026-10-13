import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/ui_library.nut" import *



let hotTurrets = mkEcsComputedEidMap({
  comps = [
    ["gun__overheat", ecs.TYPE_FLOAT],
    ["gun__owner", ecs.TYPE_EID],
  ]
  comps_rq = ["isTurret"]
  filter = "gt(gun__overheat, 0.0)"
  tags = "gameClient"
})

let watchedVehicle = mkEcsComputed({
  comps = [["human_anim__vehicleSelected", ecs.TYPE_EID]]
  comps_rq = [["watchedByPlr", ecs.TYPE_EID]]
  defVal = ecs.INVALID_ENTITY_ID
  tags = "gameClient"
})


let overheat = Computed(function() {
  if (watchedVehicle.get() == ecs.INVALID_ENTITY_ID)
    return 0
  let hero = watchedHeroEid.get()
  foreach (_eid, turret in hotTurrets.get())
    if (turret.gun__owner == hero)
      return turret.gun__overheat
  return 0
})

return overheat
