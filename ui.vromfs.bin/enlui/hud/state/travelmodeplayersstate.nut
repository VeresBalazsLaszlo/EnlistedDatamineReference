import "%enlSqGlob/weapon_slots.nut" as weaponSlots
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "dasevents" import sendNetEvent, EventSetPrechosenInfo, EventGunFound, EventUpdateTravelModeState
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/state/respawnState.nut" import curSquadData, soldiersList, curSoldierIdx
from "%ui/hud/huds/send_quick_chat_msg.nut" import sendItemHint
from "%ui/ui_library.nut" import *

let zombieModeTeamEids = Watched([])
let zombieModeTeamData = {}

isZombieObjectiveMode.subscribe(function(isZombie) {
  if (!isZombie) {
    zombieModeTeamEids.set([])
    zombieModeTeamData.clear()
  }
})


let getPlayerDataQuery = ecs.SqQuery("getPlayerDataQuery", {
  comps_ro = [
    ["name", ecs.TYPE_STRING],
    ["is_local", ecs.TYPE_BOOL, false]
  ]
})


let getVehicleTypeQuery = ecs.SqQuery("getVehicleTypeQuery", {
  comps_ro = [[ "zombie_evacuation", ecs.TYPE_TAG, null ]]
})

function isInsideEvacuation(vehEid) {
  local isEvacuating = false
  getVehicleTypeQuery(vehEid, function(_, vehComp) {
    if (vehComp.zombie_evacuation != null)
      isEvacuating = true
  })
  return isEvacuating
}


function getPlayerData(eid, comp) {
  let primaryGunEid = comp.human_weap__gunEids[weaponSlots.EWS_PRIMARY]
  let secondaryGunEid = comp.human_weap__gunEids[weaponSlots.EWS_SECONDARY]
  return {
    eid
    nickname = getPlayerDataQuery(comp.possessedByPlr, @(_eid, compPlayer) compPlayer.name)
    sKind = comp.soldier__sKind
    hpCurrent = comp.hitpoints__uiHp
    hpMax = comp.hitpoints__maxHp
    isDowned = comp.isDowned
    primaryGunName = ecs.obsolete_dbg_get_comp_val(primaryGunEid, "item__name") ?? ""
    secondaryGunName = ecs.obsolete_dbg_get_comp_val(secondaryGunEid, "item__name") ?? ""
    isEvacuating = isInsideEvacuation(comp.human_anim__vehicleSelected)
  }
}


ecs.register_es(
  "travel_mode_state_es",
  {
    [["onInit", "onChange", EventUpdateTravelModeState]] = function(_, eid, comp) {
      let isLocal = getPlayerDataQuery(comp.possessedByPlr,
        @(_eid, compPlayer) compPlayer.is_local)
      let playerData = getPlayerData(eid, comp)
      if (!zombieModeTeamEids.get().contains(eid)) {
        zombieModeTeamData[eid] <- Watched(playerData)
        zombieModeTeamEids.mutate(function(v) {
          if (isLocal)
            v.insert(0, eid)
          else
            v.append(eid)
        })
      }
      else
        zombieModeTeamData[eid].set(playerData)
    }
    function onDestroy(_, eid, __) {
      let idx = zombieModeTeamEids.get().indexof(eid)
      if (idx != null)
        zombieModeTeamEids.mutate(function(v) { v.remove(idx) })
      zombieModeTeamData.rawdelete(eid)
    }
  },
  {
    comps_rq = ["zombie_mode_human"]
    comps_track = [
      ["hitpoints__uiHp", ecs.TYPE_FLOAT],
      ["hitpoints__maxHp", ecs.TYPE_FLOAT],
      ["isDowned", ecs.TYPE_BOOL],
      ["human_weap__gunEids", ecs.TYPE_EID_LIST],
      ["possessedByPlr", ecs.TYPE_EID],
      ["human_anim__vehicleSelected", ecs.TYPE_EID],
    ]
    comps_ro = [
      ["soldier__sKind", ecs.TYPE_STRING],
    ]
  }
)

ecs.register_es(
  "gun_on_appear_es",
  {
    ["onInit"] = function(_, _eid, comp) {
      if (zombieModeTeamEids.get().contains(comp.gun__owner)) {
        ecs.g_entity_mgr.sendEvent(comp.gun__owner, EventUpdateTravelModeState())
      }
    }
  },
  {
    comps_rq = ["gun"]
    comps_ro = [["gun__owner", ecs.TYPE_EID]]
  }
)


let zombieEventSelSoldier = keepref(Computed(@()
  !isZombieObjectiveMode.get() ? null
    : !(curSquadData.get()?.canSpawn ?? false) ? ""
    : soldiersList.get()?[curSoldierIdx.get()].sKind
))

zombieEventSelSoldier.subscribe(function(sKind) {
  if (sKind != null)
    sendNetEvent(localPlayerEid.get(), EventSetPrechosenInfo({
      prechosenSKind = sKind
    }))
})


let prechosenPlayers = mkEcsComputedEidMap({
  comps = [
    ["name", ecs.TYPE_STRING],
    ["player__prechosenSKind", ecs.TYPE_STRING],
  ]
  comps_rq = ["player_zombieMode"]
})

let zombieModeTeamPrechosen = Computed(function() {
  let res = []
  foreach (eid, row in prechosenPlayers.get())
    res.append({ eid, nickname = row.name, sKind = row.player__prechosenSKind })
  res.sort(@(a, b) a.eid <=> b.eid) 
  return res
})

function onGunFound(evt, _eid, _comp) {
  sendItemHint(ecs.obsolete_dbg_get_comp_val(evt.gunEid, "item__name") ?? "", evt.gunEid, 1, loc("teammate"))
}

ecs.register_es("gun_found_es",
  {
    [EventGunFound] = onGunFound
  },
  {
    comps_rq = ["localPlayer"]
  }
)

return {
  zombieModeTeamEids
  zombieModeTeamData
  zombieModeTeamPrechosen
}
