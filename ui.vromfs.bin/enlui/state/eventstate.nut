import "%ui/userstats/serverTime.nut" as serverTime
from "dagor.system" import DBGLEVEL
from "%ui/soldiers/model/state.nut" import curCampItemsCount
from "%ui/soldiers/model/cratesContent.nut" import DropKind
from "%ui/debriefing/debriefingState.nut" import debriefingData
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/ui_library.nut" import *

const PENALTY_TIME = 300 

let isDebugPenalty = Watched(DBGLEVEL > 0)
let eventPenalty = mkOnlineSaveData("eventPenalty", @() 0)
let eventPenaltyWatch = eventPenalty.watch

let missionTypes = {
  zombie_mode = true
  gun_game = true
}

let mkEventPenaltyTime = @() Computed(function() {
  if (isDebugPenalty.get())
    return 0

  let diff = eventPenaltyWatch.get() - serverTime.get()
  return diff > 0 ? diff : 0
})

function addCrate(result, basetpl, crateId) {
  let cratesList = result?[basetpl] ?? []
  cratesList.append(crateId)
  result[basetpl] <- cratesList
}

function createCratesListForItems(crateContentWatchVal, itemsTbl) {
  let result = {}
  let inlineCrates = {}
  foreach (crateId, crate in crateContentWatchVal) {
    if (crate?.mainItem in itemsTbl)
      addCrate(result, crate.mainItem, crateId)

    foreach (possibleItems in crate?.items ?? [])
      foreach (item in possibleItems) {
        if (item.id in itemsTbl)
          addCrate(result, item.id, crateId)
        if (item.kind == DropKind.CRATE)
          inlineCrates[item.id] <- crateId
      }
  }

  foreach (cratesList in result)
    foreach (idx, crateId in cratesList) {
      local inlineId = crateId
      while (inlineId in inlineCrates) {
        inlineId = inlineCrates[inlineId]
        cratesList[idx] = inlineId
      }
    }
  return result
}

debriefingData.subscribe(function(data) {
  let { missionType = "", result = null } = data
  let { deserter = false } = result
  if ((missionType in missionTypes) && deserter)
    eventPenalty.setValue(serverTime.get() + PENALTY_TIME)
})

let hasEventDeserterPenalty = @() eventPenaltyWatch.get() > serverTime.get()

console_register_command(@(item)
  console_print(curCampItemsCount.get()?[item] ?? 0), "event.itemCount")
console_register_command(@()
  console_print($"Event penalty left: {max(eventPenaltyWatch.get() - serverTime.get(), 0)}"),
  "event.penaltyTime")
console_register_command(function() {
  isDebugPenalty.set(!isDebugPenalty.get())
  console_print($"Event deserter penalty is {isDebugPenalty.get() ? "disabled" : "active"}")
}, "event.switchPenalty")

console_register_command(function() {
  if (eventPenaltyWatch.get() > serverTime.get())
    eventPenalty.setValue(0)
  else
    eventPenalty.setValue(serverTime.get() + PENALTY_TIME)
}, "event.togglePenalty")

return {
  mkEventPenaltyTime
  hasEventDeserterPenalty
  createCratesListForItems
}
