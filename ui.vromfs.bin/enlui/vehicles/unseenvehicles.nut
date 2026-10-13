import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import chosenSquadsByArmy, armoryByArmy, vehicleBySquad, itemCountByArmy
from "%sqstd/timers.nut" import debounce
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/vehicles"

let seen = Computed(@() settings.get()?[SEEN_ID]) 

let unseenArmiesVehicle = Watched({})
let unseenSquadsVehicle = Watched({})

let notEquippedTiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let itemsList = armoryByArmy.get()?[armyId] ?? []
    let armyTpls = {}
    foreach (item in itemsList)
      if (item?.itemtype == "vehicle")
        armyTpls[item.basetpl] <- item?.growthTier ?? -1
    res[armyId] <- armyTpls
  }
  return res
})

let unseenTiers = Computed(@() !onlineSettingUpdated.get() ? {}
  : notEquippedTiers.get().map(function(tiers, armyId) {
    let armySeen = seen.get()?[armyId]
    return tiers.filter(@(_, basetpl) basetpl not in armySeen)
  }))

let chosenSquadsTiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let armyVehicles = {}
    foreach (squad in chosenSquadsByArmy.get()?[armyId] ?? []) {
      let { vehicleType = "" } = squad
      if (vehicleType != "")
        armyVehicles[squad.guid] <- {
          tier = vehicleBySquad.get()?[squad.guid].growthTier ?? -1
          squadId = squad.squadId
        }
      }
    res[armyId] <- armyVehicles
  }
  return res
})

function recalcUnseen() {
  let unseenArmies = {}
  let unseenSquads = {}

  foreach (armyId, tiers in unseenTiers.get()) {
    unseenArmies[armyId] <- 0
    foreach (squadGuid, tierData in chosenSquadsTiers.get()?[armyId] ?? []) {
      let { squadId, tier } = tierData
      let unseenVehicles = (allowedVehicles.get()?[armyId][squadId] ?? {})
        .filter(@(isUsable, vehicleTpl) isUsable && tier < (tiers?[vehicleTpl] ?? -1))

      if (unseenVehicles.len() == 0)
        continue
      unseenSquads[squadGuid] <- unseenVehicles
      unseenArmies[armyId]++
    }
  }

  unseenArmiesVehicle.set(unseenArmies)
  unseenSquadsVehicle.set(unseenSquads)
}
recalcUnseen()
let recalcUnseenDebounced = debounce(recalcUnseen, 0.01)
unseenTiers.subscribe(@(_) recalcUnseenDebounced())
chosenSquadsTiers.subscribe(@(_) recalcUnseenDebounced())
allowedVehicles.subscribe(@(_) recalcUnseenDebounced())

function markVehicleSeen(armyId, basetpl) {
  if (!onlineSettingUpdated.get() || (seen.get()?[armyId][basetpl] ?? false))
    return

  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    armySaved[basetpl] <- true
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

function markNotFreeVehiclesUnseen() {
  let seenData = seen.get() ?? {}
  if (seenData.len() == 0)
    return false

  local hasChanges = false
  let newSeen = clone seenData
  foreach (armyId, curArmySeen in seenData) {
    let counts = itemCountByArmy.get()?[armyId] ?? {}
    if (counts.len() == 0)
      continue

    let newArmySeen = curArmySeen.filter(@(_, tpl) tpl in counts)
    if (newArmySeen.len() < curArmySeen.len()) {
      newSeen[armyId] = newArmySeen
      hasChanges = true
    }
  }

  if (hasChanges)
    settings.mutate(@(set) set[SEEN_ID] <- newSeen)
  return hasChanges
}

itemCountByArmy.subscribe(function(_) {
  if (onlineSettingUpdated.get())
    markNotFreeVehiclesUnseen()
})

function markArmyVehiclesSeen(armyId) {
  foreach (vehicles in unseenSquadsVehicle.get())
    foreach (vehicleTpl, _ in vehicles)
      markVehicleSeen(armyId, vehicleTpl)
}

return {
  unseenArmiesVehicle
  unseenSquadsVehicle

  markVehicleSeen
  markArmyVehiclesSeen
}
