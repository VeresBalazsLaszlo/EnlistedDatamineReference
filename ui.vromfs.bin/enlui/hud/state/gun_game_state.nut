import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

let gunGameLevels = mkEcsComputed({
  comps = [["gun_game__levelsCount", ecs.TYPE_INT]]
})

let isGunGameMode = Computed(@() gunGameLevels.get() != null)
let gunGameLevelCount = Computed(@() gunGameLevels.get() ?? 0)


let teamGunGameLevels = mkEcsComputedEidMap({
  comps = [
    ["team__gunGameLevel", ecs.TYPE_INT],
    ["team__id", ecs.TYPE_INT]
  ]
})

let gunGameFriendlyTeamProgress = Computed(function() {
  let myTeam = localPlayerTeam.get()
  foreach (teamState in teamGunGameLevels.get())
    if (teamState.team__id == myTeam)
      return teamState.team__gunGameLevel
  return 0
})

let gunGameEnemyTeamProgress = Computed(function() {
  let myTeam = localPlayerTeam.get()
  local res = 0
  foreach (teamState in teamGunGameLevels.get())
    if (teamState.team__id != myTeam && teamState.team__gunGameLevel > res)
      res = teamState.team__gunGameLevel
  return res
})


let gunGameLeader = mkEcsComputed({
  comps = [
    ["gun_game__leaderPlayerEid", ecs.TYPE_EID],
    ["chars_gun_game__leaderIcon", ecs.TYPE_STRING]
  ]
})


let playersNameTeam = mkEcsComputedEidMap({
  comps = [
    ["name", ecs.TYPE_STRING],
    ["team", ecs.TYPE_INT]
  ]
  comps_rq = ["player"]
})

let gunGameLeaderPlayerEid = Computed(@() gunGameLeader.get()?.gun_game__leaderPlayerEid ?? ecs.INVALID_ENTITY_ID)
let gunGameLeaderIcon = Computed(@() gunGameLeader.get()?.chars_gun_game__leaderIcon ?? "")

let leaderRow = Computed(@() playersNameTeam.get()?[gunGameLeaderPlayerEid.get()])
let gunGameLeaderName = Computed(@() leaderRow.get()?.name ?? "")
let gunGameLeaderTeam = Computed(@() leaderRow.get()?.team ?? 0)


let gunGamePlayer = mkEcsComputed({
  comps = [
    ["gun_game__currentLevel", ecs.TYPE_INT],
    ["gun_game__killsForNextLevel", ecs.TYPE_INT],
    ["gun_game__killsForNextLevelRequire", ecs.TYPE_INT],
    ["chars_gun_game_player__pointsNeedToLead", ecs.TYPE_INT]
  ]
  comps_rq = ["localPlayer"]
})

let gunGamePlayerProgress = Computed(@() gunGamePlayer.get()?.gun_game__currentLevel ?? 0)
let gunGameLevelKillsRequire = Computed(@() gunGamePlayer.get()?.gun_game__killsForNextLevelRequire ?? 0)
let gunGameKillsNeedToLead = Computed(@() gunGamePlayer.get()?.chars_gun_game_player__pointsNeedToLead ?? 0)
let gunGameLevelKillsDone = Computed(function() {
  let state = gunGamePlayer.get()
  return state == null ? 0
    : state.gun_game__killsForNextLevelRequire - state.gun_game__killsForNextLevel
})


let gunGamePlayerIcon = mkEcsComputed({
  comps = [["chars_gun_game_player__currentCharIcon", ecs.TYPE_STRING]]
  comps_rq = ["localPlayer"]
  defVal = ""
  tags = "gameClient"
})


return {
  isGunGameMode
  gunGameFriendlyTeamProgress
  gunGameEnemyTeamProgress
  gunGamePlayerIcon
  gunGamePlayerProgress
  gunGameLevelKillsDone
  gunGameLevelKillsRequire
  gunGameKillsNeedToLead
  gunGameLevelCount
  gunGameLeaderPlayerEid
  gunGameLeaderName
  gunGameLeaderTeam
  gunGameLeaderIcon
}