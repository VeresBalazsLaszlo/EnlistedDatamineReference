from "%ui/hud/state/squad_members.nut" import watchedHeroSquadMembers
from "%ui/ui_library.nut" import *

function getEngineersCount(list){
  local enginersCount = 0
  foreach (soldier in list){
    if (soldier.isAlive && soldier.weapTemplates.secondary.contains("building_tool"))
      enginersCount++
  }
  return enginersCount
}

let engineersInSquad = Computed(@() getEngineersCount(watchedHeroSquadMembers.get()))

return engineersInSquad