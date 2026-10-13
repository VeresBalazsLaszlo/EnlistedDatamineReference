import "%ui/soldiers/model/armyEffects.nut" as armyEffects
from "%sqstd/underscore.nut" import tablesCombine
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

function calcSquadParams(effects, squadId, squad) {
  let size = squad.size + (effects?.squad_size[squadId] ?? 0)
  return {
    size = size
    maxClasses = tablesCombine(squad?.maxClasses ?? {},
      effects?.squad_class_limit[squadId] ?? {},
      @(a, b) min(a + b, size),
      0)
  }
}

let squadsParams = Computed(function() {
  let effects = armyEffects.get()
  return squadsCfgById.get().map(
    @(armySquads, armyId) armySquads.map(
      @(squad, squadId) calcSquadParams(effects?[armyId], squadId, squad)))
})

return squadsParams