import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid, localPlayerGroupId
from "matching.errors" import INVALID_SQUAD_ID
from "%ui/ec_to_watched.nut" import mkWatchedSetAndStorage, mkFrameIncrementObservable
from "ecs.computed" import mkEcsComputedEidMap
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let players = mkEcsComputedEidMap({
  comps = [
    ["groupId", ecs.TYPE_INT64],
    ["player_group__memberIndex", ecs.TYPE_INT]
  ]
  comps_rq = ["player"]
  comps_no = ["playerIsBot"]
})


let heroesTrackComps = [
  ["team", ecs.TYPE_INT],
  ["possessedByPlr", ecs.TYPE_EID],
  ["human_anim__vehicleSelected", ecs.TYPE_EID],
  ["squad_member__squad", ecs.TYPE_EID],
  ["squad_member__playerEid", ecs.TYPE_EID],
  ["human_quickchat__requestAmmoBoxMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["human_quickchat__requestRallyPointMarkerShowUpTo", ecs.TYPE_FLOAT],
  ["medic__healState", ecs.TYPE_INT],
  ["isAlive", ecs.TYPE_BOOL],
]

let teammatePlayerInfoQuery = ecs.SqQuery("teammatePlayerInfoQuery", {
  comps_ro = [
    ["disconnected", ecs.TYPE_BOOL],
    ["groupId", ecs.TYPE_INT64, INVALID_SQUAD_ID],
    ["player_group__memberIndex", ecs.TYPE_INT],
    ["name", ecs.TYPE_STRING],
    ["decorators__nickFrame", ecs.TYPE_STRING],
  ]
})

let humanTeammatesStatsQuery = ecs.SqQuery("humanTeammatesStatsQuery", {
  comps_rq = ["human"]
  comps_no = ["watchedByPlr", "deadEntity"]
  comps_ro = heroesTrackComps
})

let {alivePossessedTeammates, alivePossessedTeammatesModify, alivePossessedTeammatesSetKeyVal, alivePossessedTeammatesDeleteKey} = mkFrameIncrementObservable({}, "alivePossessedTeammates")

let {
  teammatesAvatarsSet,
  teammatesAvatarsGetWatched,
  teammatesAvatarsUpdateEid,
  teammatesAvatarsDestroyEid
} = mkWatchedSetAndStorage("teammatesAvatars")

function set_human_teammates_stats(player_team, eid, comp) {
  if (player_team != comp.team) {
    teammatesAvatarsDestroyEid(eid)
    alivePossessedTeammatesDeleteKey(eid)
    return
  }

  let res = {}
  foreach (i in heroesTrackComps)
    res[i[0]] <- comp[i[0]]
  res.isAlive <- comp.isAlive
  res.eid <- eid
  teammatePlayerInfoQuery(comp.possessedByPlr, @(_, playerComp) res.__update(playerComp))

  teammatesAvatarsUpdateEid(eid, res)
  if (comp.possessedByPlr == ecs.INVALID_ENTITY_ID || localPlayerEid.get() == comp.squad_member__playerEid) {
    alivePossessedTeammatesDeleteKey(eid)
  }
  else {
    alivePossessedTeammatesSetKeyVal(eid, res)
  }
}

ecs.register_es("human_teammates_stats_ui_es",
  {
    [["onChange","onInit"]] = @(_evt, eid, comp) set_human_teammates_stats(localPlayerTeam.get(), eid, comp),
    function onDestroy(_evt, eid, _comp){
      teammatesAvatarsDestroyEid(eid)
      alivePossessedTeammatesDeleteKey(eid)
    }
  },
  {
    comps_rq = ["human"]
    comps_no = ["watchedByPlr", "deadEntity"]
    comps_track = heroesTrackComps
  }
)

localPlayerTeam.subscribe(@(team) humanTeammatesStatsQuery(@(eid, comp) set_human_teammates_stats(team, eid, comp)))



ecs.register_es("human_teammates_players_ui_es",
  {
    [["onInit", "onChange"]] = function(_evt, _eid, comp){
      if (comp["is_local"] || comp["team"] != localPlayerTeam.get()){
        return
      }
      let {possessed, name, groupId, disconnected, player_group__memberIndex} = comp
      alivePossessedTeammatesModify(function(value) {
        value?[possessed]?.__update({name, groupId, player_group__memberIndex, disconnected})
        return value
      })
    },
  },
  {
    comps_ro = [
      ["platform", ecs.TYPE_STRING, ""]
    ],
    comps_track = [
      ["team", ecs.TYPE_INT],
      ["is_local", ecs.TYPE_BOOL, false],
      ["disconnected", ecs.TYPE_BOOL],
      ["possessed", ecs.TYPE_EID],
      ["groupId", ecs.TYPE_INT64],
      ["player_group__memberIndex", ecs.TYPE_INT],
      ["name", ecs.TYPE_STRING],
      ["decorators__nickFrame", ecs.TYPE_STRING, null]
    ],
    comps_rq = ["player"]
  }
)

let teammatesAliveNum = Computed(@() alivePossessedTeammates.get().filter(@(teammate) !(teammate?.disconnected ?? true)).len())
let groupmatesAvatars = Computed(@() alivePossessedTeammates.get().filter(@(teammate)
  localPlayerGroupId.get() != INVALID_SQUAD_ID && (teammate?.groupId ?? INVALID_SQUAD_ID) == localPlayerGroupId.get()))

let groupmatesAvatarsStorage = {}
let groupmatesAvatarsGetWatched = @(eid) groupmatesAvatarsStorage?[eid]

let groupmatesAvatarsSet = Watched({})
function updateGroupmatesAvatarsSetAndStorage(v){
  let s = v.map(function(_, eid) {
    if (eid not in groupmatesAvatarsStorage)
      groupmatesAvatarsStorage[eid] <- Computed(@() groupmatesAvatars.get()?[eid]) 
    return eid
  })
  let toDelete = []
  foreach (eid, _ in groupmatesAvatarsStorage){
    if (eid not in s)
      toDelete.append(eid)
  }
  foreach (eid in toDelete){
    groupmatesAvatarsStorage.$rawdelete(eid)
  }
  groupmatesAvatarsSet.set(s)
}

let groupmateIds = Computed(function() {
  let result = {}
  let localGroupId = localPlayerGroupId.get()

  foreach (eid, data in players.get()) {
    if (data.groupId == localGroupId) {
      result[eid] <- data.player_group__memberIndex
    }
  }

  return result
})

subscribeAndInit(updateGroupmatesAvatarsSetAndStorage, groupmatesAvatars)

return {
  teammatesAvatarsSet
  teammatesAvatarsNotGroupmatesSet = Computed(function() {
    let groupmates = groupmatesAvatars.get()
    return teammatesAvatarsSet.get().filter(@(_, eid) eid not in groupmates)
  })
  teammatesAvatarsGetWatched
  groupmatesAvatarsGetWatched
  groupmatesAvatarsSet
  teammatesAliveNum 
  groupmateIds
}
