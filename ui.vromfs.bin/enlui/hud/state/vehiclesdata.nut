import "%ui/hud/state/armyData.nut" as armyData
import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

function getCrewCount(template) {
  let gametemplate = template == null ? null
    : ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  if (gametemplate == null)
    return 0
  return gametemplate.getCompValNullable("vehicle_seats__seats")?.len() ?? 0
}

function collectVehicleData(vehicle, armyId, squadId, country, growthTier) {
  let res = {}
  foreach (key in ["guid", "gametemplate"])
    res[key] <- vehicle[key]

  return res.__update({
    armyId = armyId
    squadId = squadId
    country = country
    crew = getCrewCount(vehicle.gametemplate)
    growthTier = growthTier
  })
}

let vehicles = Computed(function() {
  let res = {}
  let squadsList = armyData.get()?.squads
  if (squadsList == null)
    return res

  let armyId = armyData.get().armyId
  let country = armyData.get().country
  foreach (squad in squadsList) {
    let vehicle = squad?.curVehicle
    if (vehicle != null)
      res[vehicle.guid] <- collectVehicleData(vehicle, armyId, squad.squadId, country, squad?.curVehicle?.growthTier ?? 1)
  }
  return res
})

return vehicles