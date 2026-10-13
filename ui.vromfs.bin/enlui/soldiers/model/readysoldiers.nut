import "%ui/soldiers/model/squadsParams.nut" as squadsParams
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesConfig
from "%sqstd/timers.nut" import debounce
from "%ui/soldiers/model/state.nut" import curSquad, curSquadSoldiersInfo, soldiersBySquad, vehicleBySquad
from "%ui/helpers/metalink.nut" import getLinkedArmyName, getLinkedSlotData
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/meta/profile.nut" import curCampSquads, curCampSoldiers, curCampItems
from "%ui/ui_library.nut" import *

let readyStatus = require("%ui/soldiers/readyStatus.nut")
let { READY, OUT_OF_VEHICLE, TOO_MUCH_CLASS, OUT_OF_SQUAD_SIZE, NOT_READY_BY_EQUIP } = readyStatus

let invalidEquipSoldiers = mkWatched(persist, "invalidEquipSoldiers")

function updateInvalidSoldiers() {
  let equippedItems = {}
  foreach (item in curCampItems.get()) {
    let sd = getLinkedSlotData(item)
    if (sd == null)
      continue
    let { linkTgt, linkSlot } = sd
    if (linkTgt not in equippedItems)
      equippedItems[linkTgt] <- {}
    equippedItems[linkTgt][linkSlot] <- item
  }

  let invalid = curCampSoldiers.get()
    .filter(function(soldier) {
      if (soldier?.hasVerified == false)
        return true

      let { equipScheme = null } = soldier
      if (equipScheme == null)
        return false 

      let slotsData = {}
      foreach (slotType, slot in equipScheme) {
        let { atLeastOne = "" } = slot
        if (atLeastOne == "" || slotsData?[atLeastOne] == true)
          continue

        let item = equippedItems?[soldier.guid][slotType]
        slotsData[atLeastOne] <- item != null
        if (item == null)
          continue

        local { basetpl, itemtype = null } = item
        basetpl = trimUpgradeSuffix(basetpl)
        let { items = [], itemTypes = [] } = slot
        if ((itemTypes.len() != 0 || items.len() != 0)
            && !itemTypes.contains(itemtype)
            && !items.contains(basetpl))
          return true
      }
      return slotsData.findindex(@(s) !s) != null
    })
    .map(@(_) true)

  if (!isEqual(invalid, invalidEquipSoldiers.get()))
    invalidEquipSoldiers.set(invalid)
}
if (invalidEquipSoldiers.get() == null)
  updateInvalidSoldiers()
let updateInvalidSoldiersDebounced = debounce(updateInvalidSoldiers, 0.01)
curCampItems.subscribe(@(_) updateInvalidSoldiersDebounced())
curCampSoldiers.subscribe(@(_) updateInvalidSoldiersDebounced())

let getSoldiersBattleReady = kwarg(
  function(squadSize, maxClasses, soldiers, vehicle, invalidSoldiers, classesCfg) {
    let res = {}
    let vehicleSize = vehicle?.crew ?? squadSize
    local totalReady = 0
    let usedClasses = {}
    foreach (soldier in soldiers) {
      local state = READY
      let sKind = soldier?.sKind ?? classesCfg?[soldier.sClass].kind
      if (sKind == null)
        continue
      if (soldier.guid in invalidSoldiers)
        state = state | NOT_READY_BY_EQUIP
      else if (totalReady >= squadSize)
        state = state | OUT_OF_SQUAD_SIZE
      else if ((usedClasses?[sKind] ?? 0) >= (maxClasses?[sKind] ?? 0))
        state = state | TOO_MUCH_CLASS
      else {
        if (totalReady >= vehicleSize)
          state = state | OUT_OF_VEHICLE
        totalReady++
        usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
      }

      res[soldier.guid] <- state
    }

    return res
  })

let soldiersStatuses = Computed(function() {
  let res = {}
  let sqParams = squadsParams.get()
  foreach (squad in curCampSquads.get()) {
    let armyId = getLinkedArmyName(squad)
    let params = sqParams?[armyId][squad.squadId]
    if (params == null)
      continue

    let vehicleGuid = vehicleBySquad.get()?[squad.guid].guid
    res.__update(getSoldiersBattleReady({
      squadSize = params?.size ?? 0
      maxClasses = params?.maxClasses ?? {}
      soldiers = (soldiersBySquad.get()?[squad.guid] ?? [])
        .map(@(soldier) curCampSoldiers.get()?[soldier.guid] ?? soldier)
      vehicle = vehicleGuid ? curCampItems.get()?[vehicleGuid] : null
      invalidSoldiers = invalidEquipSoldiers.get()
      classesCfg = sClassesConfig.get()
    }))
  }
  return res
})

let curSquadSoldiersStatus = Computed(function() {
  let res = {}
  foreach (soldier in soldiersBySquad.get()?[curSquad.get()?.guid] ?? [])
    res[soldier.guid] <- soldiersStatuses.get()?[soldier.guid] ?? OUT_OF_SQUAD_SIZE
  return res
})

let curSquadSoldiersReady = Computed(@() curSquadSoldiersInfo.get().filter(@(soldier)
  curSquadSoldiersStatus.get()?[soldier?.guid] == READY))

return {
  soldiersStatuses = soldiersStatuses
  curSquadSoldiersStatus = curSquadSoldiersStatus
  curSquadSoldiersReady = curSquadSoldiersReady
  invalidEquipSoldiers = invalidEquipSoldiers
}.__update(readyStatus)
