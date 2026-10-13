import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerEid
from "%ui/hud/style.nut" import TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { EventGunGameLevelReached = null, EventGunGameNewLeader = null } = require("dasevents")



if (EventGunGameLevelReached == null || EventGunGameNewLeader == null)
  return

let showMsg = @(text, color) playerEvents.pushEvent({ text, color, ttl = 4 })

let getColorByTeam = @(other_team) other_team == localPlayerTeam.get() ? TEAM0_TEXT_COLOR : TEAM1_TEXT_COLOR

let getPlayerNameAndTeamQuery = ecs.SqQuery("getPlayerNameAndTeamQuery", { comps_ro = [
  ["name", ecs.TYPE_STRING],
  ["team", ecs.TYPE_INT]
] })
let getPlayerNameQuery = ecs.SqQuery("getPlayerNameQuery", { comps_ro = [["name", ecs.TYPE_STRING]] })

ecs.register_es("gun_game_level_reached_hint", {
  [EventGunGameLevelReached] = function(evt, _eid, _comp) {
    getPlayerNameAndTeamQuery(evt.playerEid, function(_eid, comp) {
      showMsg(loc("gun_game/levelReached",
        { name = remap_others(comp.name), level = evt.level + 1 }), getColorByTeam(comp.team))
    })
  }
}, {}, { tags = "gameClient" })

ecs.register_es("gun_game_leader_change_hint", {
  [EventGunGameNewLeader] = function(evt, _eid, _comp) {
    getPlayerNameAndTeamQuery(evt.newLeaderPlayerEid, function(_eid, comp) {
      
      if (evt.oldLeaderPlayerEid == ecs.INVALID_ENTITY_ID)
        if (evt.newLeaderPlayerEid != localPlayerEid.get())
          showMsg(loc("gun_game/firstLeadTaken", { name = remap_others(comp.name) }), getColorByTeam(comp.team))
        else
          showMsg(loc("gun_game/firstLeadTakenSelf"), getColorByTeam(comp.team))
      else if (evt.oldLeaderPlayerEid == localPlayerEid.get())
        showMsg(loc("gun_game/leaderTakenFromUs", { name = remap_others(comp.name) }), getColorByTeam(comp.team))
      else if (evt.newLeaderPlayerEid == localPlayerEid.get()) {
        let oldLeaderName = getPlayerNameQuery(evt.oldLeaderPlayerEid, @(_eid, compLeader) compLeader.name)
        showMsg(loc("gun_game/leaderTakenByUs", { name = remap_others(oldLeaderName) }), getColorByTeam(comp.team))
      }
      else
        showMsg(loc("gun_game/leaderTaken", { name = remap_others(comp.name) }), getColorByTeam(comp.team))
    })
  }
}, {}, { tags = "gameClient" })
