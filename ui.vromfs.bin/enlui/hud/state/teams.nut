import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *



let teams = mkEcsComputedEidMap({
  comps = [
    ["team__id", ecs.TYPE_INT],
    ["team__name", ecs.TYPE_STRING, ""],
    ["team__armyId", ecs.TYPE_STRING, ""],
    ["team__armies", ecs.TYPE_STRING_LIST],
    ["team__maxSpySquads", ecs.TYPE_INT, -1],
    ["team__memberCount", ecs.TYPE_FLOAT, 0.0],
    ["team__hasSpawns", ecs.TYPE_BOOL, true],
    ["team__briefing", ecs.TYPE_STRING, ""],
    ["team__narrator", ecs.TYPE_OBJECT, {}],
    ["team__squadsCanSpawn", ecs.TYPE_BOOL, true],
    ["team__eachSquadMaxSpawns", ecs.TYPE_INT, 0],
    ["team__goalShowTime", ecs.TYPE_FLOAT, -1.0],
    ["team__forceEnableBriefing", ecs.TYPE_BOOL, false],
    ["team__aliveSpySquads", ecs.TYPE_INT, 0]
  ]
})

let localPlayerTeamInfo = Computed(function(){
  foreach (team in teams.get()) {
    if (team?["team__id"] != null && team?["team__id"] == localPlayerTeam.get())
      return team
  }
  return null
})
let localPlayerTeamArmyId = Computed(@() localPlayerTeamInfo.get()?["team__armyId"])
let localPlayerTeamSquadsCanSpawn = Computed(@() localPlayerTeamInfo.get()?["team__squadsCanSpawn"] ?? true)
let canSpawnSpySquad = Computed(function() {
  let maxSpySquads = localPlayerTeamInfo.get()?["team__maxSpySquads"] ?? -1
  if (maxSpySquads < 0)
    return true
  let aliveSpySquads = localPlayerTeamInfo.get()?["team__aliveSpySquads"] ?? 0
  return aliveSpySquads < maxSpySquads
})
let localPlayerTeamArmies = Computed(function(prev) {
  let res = localPlayerTeamInfo.get()?["team__armies"] ?? []
  return prev != FRP_INITIAL && isEqual(res, prev) ? prev : res
})


return {
  teams
  localPlayerTeamArmyId
  localPlayerTeamInfo
  localPlayerTeamSquadsCanSpawn
  localPlayerTeamArmies
  canSpawnSpySquad
}
