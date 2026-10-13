import "%dngscripts/ecs.nut" as ecs
let noBotsModeQuery = ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})
let isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

enum MissionType {
  NONE = ""
  INVASION = "invasion"
  CONFRONTATION = "confrontation"
  DESTRUCTION = "destruction"
  ASSAULT = "assault"
  DOMINATION = "domination"
  ESCORT = "escort"
  GUN_GAME = "gun_game"
  ZOMBIE_MODE = "zombie_mode"
  TUTORIAL = "tutorial"
  PRACTICE = "practice"
  WW1 = "WW1"
}

let friendlyFireModeQuery = ecs.SqQuery("friendlyFireModeQuery", {comps_rq=["gamemodeFriendlyFire"]})
let isFriendlyFireMode = @() friendlyFireModeQuery.perform(@(...) true) ?? false

let missionTypeQuery = ecs.SqQuery("missionTypeQuery", {comps_ro=[["mission_type", ecs.TYPE_STRING]]})
let getMissionType = @() missionTypeQuery.perform(@(_, comp) comp.mission_type)

let scoreModeQuery = ecs.SqQuery("scoreModeQuery", {comps_ro=[["score_mode", ecs.TYPE_STRING]]})
let getScoreMode = @() scoreModeQuery.perform(@(_, comp) comp.score_mode) ?? "squads"

return freeze({
  isNoBotsMode
  isFriendlyFireMode
  getMissionType
  MissionType
  getScoreMode
})
