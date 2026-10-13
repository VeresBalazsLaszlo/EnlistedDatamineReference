import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/ui_library.nut" import *

let bombSites = mkEcsComputedEidMap({
  comps = [
    ["bomb_site__operator", ecs.TYPE_EID],
    ["bomb_site__isBombPlanted", ecs.TYPE_BOOL],
    ["bomb_site__plantedTimeEnd", ecs.TYPE_FLOAT],
    ["bomb_site__resetTimeEnd", ecs.TYPE_FLOAT],
    ["bomb_site__defusedTimeEnd", ecs.TYPE_FLOAT],
    ["bomb_site__timeToPlant", ecs.TYPE_FLOAT],
    ["bomb_site__timeToResetPlant", ecs.TYPE_FLOAT],
    ["bomb_site__timeToDefuse", ecs.TYPE_FLOAT],
  ]
  tags = "gameClient"
})



let selectedBombSite = Computed(function() {
  let hero = controlledHeroEid.get()
  if (hero == ecs.INVALID_ENTITY_ID)
    return ecs.INVALID_ENTITY_ID
  foreach (eid, site in bombSites.get())
    if (site.bomb_site__operator == hero)
      return eid
  return ecs.INVALID_ENTITY_ID
})

let operatedSite = Computed(@() bombSites.get()?[selectedBombSite.get()])

let isBombPlanted = Computed(@() operatedSite.get()?.bomb_site__isBombPlanted ?? false)
let bombPlantedTimeEnd = Computed(@() operatedSite.get()?.bomb_site__plantedTimeEnd ?? 0.0)
let bombResetTimeEnd = Computed(@() operatedSite.get()?.bomb_site__resetTimeEnd ?? 0.0)
let bombDefuseTimeEnd = Computed(@() operatedSite.get()?.bomb_site__defusedTimeEnd ?? 0.0)
let bombTimeToPlant = Computed(@() operatedSite.get()?.bomb_site__timeToPlant ?? 0.0)
let bombTimeToResetPlant = Computed(@() operatedSite.get()?.bomb_site__timeToResetPlant ?? 0.0)
let bombTimeToDefuse = Computed(@() operatedSite.get()?.bomb_site__timeToDefuse ?? 0.0)

return {
  selectedBombSite
  isBombPlanted
  bombPlantedTimeEnd
  bombResetTimeEnd
  bombDefuseTimeEnd
  bombTimeToPlant
  bombTimeToResetPlant
  bombTimeToDefuse
}