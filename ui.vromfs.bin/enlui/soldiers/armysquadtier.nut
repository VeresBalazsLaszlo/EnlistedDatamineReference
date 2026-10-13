import "%enlSqGlob/userInfo.nut" as userInfo
import "%dngscripts/ecs.nut" as ecs
from "gameevents" import EventLevelLoaded
from "%ui/meta/profile.nut" import campItemsByLink, curCampSquads
from "%ui/soldiers/model/state.nut" import curArmy, soldiersBySquad, chosenSquadsByArmy,
  getSoldierByGuid, vehicleBySquad
from "%ui/squad/squadState.nut" import allMembersState, isSquadLeader, squadId as curSquadId
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgOrdered
from "%ui/soldiers/model/all_items_templates.nut" import itemTypesInSlots, allItemTemplates
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/helpers/metalink.nut" import getFirstLinkByType
from "dasevents" import sendNetEvent, CmdSendArmyBr
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/ui_library.nut" import *

const MAX_BR = 5

let BRInfoBySquads = nestWatched("BRInfoBySquads", {})
let BRByArmies = nestWatched("BRByArmies", {})

let allArmiesTiers = Computed(@() {
  armies = BRByArmies.get()
  player = userInfo.get()?.name
})

userInfo.subscribe(function(v) {
  if (v)
    return

  BRInfoBySquads.set({})
  BRByArmies.set({})
})

let getLiveArmyBR = @(watchVal, armyId) watchVal?[armyId] ?? 1
let getArmyBR = @(armyId) getLiveArmyBR(BRByArmies.get(), armyId)

let squadsDefaultBR = Computed(function() {
  let res = {}
  foreach (armyId, squadList in squadsCfgOrdered.get()) {
    let armyTemplates = allItemTemplates.get()?[armyId]
    foreach (squad in squadList) {
      let { id, newWeapon = [], startVehicle = null } = squad
      local br = armyTemplates?[startVehicle].growthTier ?? 1
      foreach (weaponTpl in newWeapon) {
        if (br == MAX_BR)
          break
        let { growthTier = 0 } = armyTemplates?[weaponTpl]
        br = max(br, growthTier)
      }
      res[id] <- br
    }
  }
  return res
})

function getSoldierBRImpl(soldierGuid, weaponTypes, campItems) {
  let { mainWeapon } = weaponTypes
  local br = 1
  foreach (slotType, itemsList in campItems?[soldierGuid] ?? {}) {
    if (slotType == "secondary" || slotType == "primary")
      foreach (item in itemsList) {
        let { growthTier = 1 } = item
        br = max(br, growthTier)
      }
    else
      foreach (item in itemsList)
        if (item?.itemtype in mainWeapon) {
          let { growthTier = 1 } = item
          br = max(br, growthTier)
        }
    if (br == MAX_BR)
      break
  }
  return br
}

let getSoldierBR = @(soldierGuid)
  getSoldierBRImpl(soldierGuid, itemTypesInSlots.get(), campItemsByLink.get())

function getLiveSquadBR(watchVal, squadId) {
  local br = watchVal?[squadId] ?? squadsDefaultBR.get()?[squadId] ?? 0
  if (br > 0)
    return br

  log($"No battle rating for {squadId}")
  return 1
}

let getSquadBR = @(squadId) getLiveSquadBR(BRInfoBySquads.get(), squadId)

function countSquadBR(squadGuid) {
  if (squadGuid == null)
    log("countSquadBR: empty squad data")

  local br = vehicleBySquad.get()?[squadGuid].growthTier ?? 1
  foreach (soldier in soldiersBySquad.get()?[squadGuid] ?? []) {
    if (br == MAX_BR)
      break
    br = max(br, getSoldierBR(soldier.guid))
  }
  return br
}

function updateSquadsBR(squads, forceRecalc = false) {
  let newWatchTable = clone BRInfoBySquads.get()
  local hasChanges = false
  foreach (squad in squads) {
    let { squadId = null } = squad
    if (squadId == null)
      continue

    if (forceRecalc || squadId not in newWatchTable) {
      newWatchTable[squadId] <- countSquadBR(squad.guid)
      hasChanges = true
    }
  }
  if (hasChanges)
    BRInfoBySquads.set(newWatchTable)
}

function writeBRForArmy(armyId, br) {
  if (br != (BRByArmies.get()?[armyId] ?? 0))
    BRByArmies.mutate(@(v) v[armyId] <- br)
}

function updateBRForArmySquads(armyId, squadsList) {
  local br = 1
  foreach (squad in squadsList ?? []) {
    if (squad == null)
      continue

    br = max(br, getSquadBR(squad.squadId))
    if (br == MAX_BR)
      break
  }

  writeBRForArmy(armyId, br)
  return br
}

let updateBRForArmy = @(armyId) updateBRForArmySquads(armyId, chosenSquadsByArmy.get()?[armyId])

ecs.register_es("send_army_br_for_local_matches",
  { [EventLevelLoaded] = function(_evt, _eid, _comp) {
    if (curArmy.get() != null)
      sendNetEvent(localPlayerEid.get(), CmdSendArmyBr({ armyBr = updateBRForArmy(curArmy.get()) }))
    }
  },
  {},
  {tags="gameClient"}
)

function updateBRForSquad(squadGuid) {
  let { squadId = null } = curCampSquads.get()?[squadGuid]
  if (squadId not in BRInfoBySquads.get()) {
    log($"Squad {squadId} not found in the rating table. Update ignored")
    return
  }

  let squadBR = countSquadBR(squadGuid)
  BRInfoBySquads.mutate(@(v) v[squadId] <- squadBR)
  let armyId = curArmy.get()
  let armyBR = getArmyBR(armyId)
  if (squadBR > armyBR)
    writeBRForArmy(armyId, squadBR)
  else
    updateBRForArmy(armyId)
}

function updateArmyInfo(armyId) {
  if ((armyId ?? "") == "")
    return

  let squads = chosenSquadsByArmy.get()?[armyId] ?? []
  updateSquadsBR(squads, true)
  updateBRForArmy(armyId)
}

function updateAllArmies() {
  foreach (armyId, squads in chosenSquadsByArmy.get()) {
    updateSquadsBR(squads, true)
    updateBRForArmy(armyId)
  }
}





chosenSquadsByArmy.subscribe(function(_) {
  
  
  if (BRInfoBySquads.get().len() == 0)
    updateAllArmies()
  else
    updateArmyInfo(curArmy.get())
})

function updateBROnItemChange(targetGuid) {
  let soldier = getSoldierByGuid(targetGuid)
  if (soldier == null)
    
    return

  let squadGuid = getFirstLinkByType(soldier, "squad")
  if (squadGuid == null) 
    return

  updateBRForSquad(squadGuid)
}

let maxMatesArmiesTiers = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = {}

  let membersList = allMembersState.get() ?? {}
  let res = {}
  foreach (id, member in membersList) {
    let { armiesTiers = {}, ready = false } = member
    let isMemberLeader = id == curSquadId.get()
    if (armiesTiers.len() == 0 || (!isMemberLeader && !ready))
      continue

    let { armies, player } = armiesTiers
    let memberArmies = isMemberLeader && isSquadLeader.get() ? BRByArmies.get() : armies
    memberArmies.each(function(armyTier, armyId) {
      local { tier = 0, players = [] } = res?[armyId]
      if (tier == armyTier)
        players.append(player)
      else if (tier < armyTier) {
        players = [player]
        tier = armyTier
      }
      res[armyId] <- { tier, players }
    })
  }
  return isEqual(prev, res) ? prev : res
})

return {
  allArmiesTiers
  maxMatesArmiesTiers

  BRInfoBySquads
  BRByArmies

  getArmyBR
  getLiveArmyBR
  getSquadBR
  getLiveSquadBR
  getSoldierBR
  updateSquadsBR

  updateBROnMatchStart = updateAllArmies
  calcBROnSoldierChange = updateBRForSquad
  updateBROnItemChange
  updateBROnVehicleChange = updateBRForSquad
  updateBROnSquadsChange = updateBRForArmySquads

  getSoldierBRImpl
}
