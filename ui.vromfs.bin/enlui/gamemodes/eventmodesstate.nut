import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/components/mkSquadsList.nut" as mkCurSquadsList
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/matchingClient.nut" import matchingCall
from "app" import get_app_id
from "eventbus" import eventbus_subscribe
from "matching.api" import matching_listen_notify
from "%sqstd/timers.nut" import debounce
from "%ui/gameModes/gameModeState.nut" import eventGameModes
from "%ui/userstats/userstat.nut" import userstatLbStats, MAX_DELAY_FOR_MASSIVE_REQUEST_SEC
from "%ui/gameModes/createEventRoomCfg.nut" import allModes, isRoomCfgActual, actualizeRoomCfg
from "%ui/featureFlags.nut" import hasCustomGames, showEventsWidget
from "%sqstd/json.nut" import loadJson
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN, allArmies
from "%ui/ui_library.nut" import *

let isEventModesOpened = nestWatched("isEventModesOpened", false)
let customRoomsModeSaved = nestWatched("customRoomsModeSaved", false)
let hasCustomRooms = Computed(@()
  !isNewbie.get() && allModes.get().len() > 0 && hasCustomGames.get())
let isCustomRoomsMode = Computed(@() customRoomsModeSaved.get() && hasCustomRooms.get())
let selEventIdByPlayer = nestWatched("selEventByPlayer", null)
let curEventSquadId = nestWatched("curEventSquadId", null)
let eventCurArmyId = nestWatched("eventCurArmyId", 0)
let eventCustomProfile = nestWatched("eventCustomProfile", null)

let curTab = Watched(null)

let hasBaseEvent = Computed(@() showEventsWidget.get()
  && (hasCustomRooms.get() || eventGameModes.get().len() > 0))

let inactiveEventsToShow = Computed (@()
  eventGameModes.get().filter(@(gm) gm.showWhenInactive && !gm.isEnabled))

let activeEvents = Computed (@() eventGameModes.get().filter(@(gm) gm.isEnabled))

let allEventsToShow = Computed (@() [].extend(activeEvents.get(), inactiveEventsToShow.get()))

let isEventPlayable = @(eventId) activeEvents.get().findvalue(@(gm) gm.id == eventId )

let promotedEvent = Computed(@()
  allEventsToShow.get().findvalue(@(gm) gm.isPreviewImage)
    ?? allEventsToShow.get()?[0])

let selEvent = Computed(@()
  eventGameModes.get().findvalue(@(gm) gm.id == selEventIdByPlayer.get())
    ?? eventGameModes.get()?[0])

let selLbMode = Computed(@() selEvent.get()?.leaderboardTables[0])

let eventCustomProfilePath = keepref(Computed(@() selEvent.get()?.customProfile))

function reloadCustomProfile(path) {
  if (path == null)
    eventCustomProfile.set(null)
  else {
    let customData = loadJson(path)
    defer(@() eventCustomProfile.set(customData))
  }
}
eventCustomProfilePath.subscribe(reloadCustomProfile)


let eventCustomSquads = Computed(function() {
  let customProfileData = eventCustomProfile.get()
  if (customProfileData == null)
    return null

  let armyId = eventCurArmyId.get()
  let { squads = [] } = customProfileData?[armyId]
  if (squads.len() == 0)
    return null

  return squads
    .map(function(squad) {
      let { squadId = "", locId = null, squadType = "unknown", level = 0,
        curVehicle = null, vehicleType = null } = squad
      let squadDesc = getSquadPresentation(squadId, armyId) ?? getSquadPresentation(squadId)
      local { premIcon = squadDesc?.premIcon } = squad
      if ((squad?.battleExpBonus ?? 0) > 0)
        
        premIcon = premIcon ?? armiesPresentation?[armyId].premIcon
      let { icon = squadDesc?.icon } = squad
      return {
        squadId
        icon
        premIcon
        name = loc(locId, "---")
        squadType
        level
        squadSize = squad.squad.len()
        vehicle = curVehicle
        vehicleType
      }
    })
})

eventCustomSquads.subscribe(function(squads) {
  if (squads == null)
    return

  let curSquadId = curEventSquadId.get()
  let notFound = squads.findvalue(@(squad) squad.squadId == curSquadId) == null
  if (notFound)
    curEventSquadId.set(squads[0].squadId)
})

let eventsArmiesList = Computed(function() {
  if (!isEventModesOpened.get())
    return []

  let armyList = selEvent.get()?.queues[0].extraParams.armies ?? allArmies.get()[COMMON_CAMPAIGN]
  if (eventCustomProfile.get() == null)
    return armyList

  let uniqueArmyList = eventCustomProfile.get().keys()
  let armiesCustomProfile = []
  foreach (armyId in armyList)
    if (uniqueArmyList.contains(armyId))
      armiesCustomProfile.append(armyId)
  return armiesCustomProfile.len() <= 1 ? uniqueArmyList : armiesCustomProfile
})

let eventsSquadList = @(squads) mkCurSquadsList({
  curSquadsList = squads
  curSquadId = curEventSquadId
  setCurSquadId = @(squadId) curEventSquadId.set(squadId)
})

let selEventEndTime = Computed(function() {
  let time = userstatLbStats.get()?.stats[selLbMode.get()]["$endsAt"].tointeger() ?? 0
  return time
})

let needActualizeCfg = keepref(Computed(@() !isRoomCfgActual.get() && isEventModesOpened.get()))
needActualizeCfg.subscribe(function(v) { if (v) actualizeRoomCfg() })

function openCustomGameMode() {
  customRoomsModeSaved.set(true)
  isEventModesOpened.set(true)
}

function openEventsGameMode() {
  customRoomsModeSaved.set(false)
  isEventModesOpened.set(true)
}

let eventStartTime = Watched({})

function nearestTime(mmEvent, mmAction, timeTable) {
  if (mmEvent.action == mmAction && (mmEvent.queue_id not in timeTable
      || mmEvent.time < timeTable[mmEvent.queue_id]) )
    timeTable[mmEvent.queue_id] <- mmEvent.time
}

local isMMScheduleProcessed = false

function timeUntilStart() {
  if (isMMScheduleProcessed)
    return

  matchingCall("enlmm.get_schedule_list",
    function(response) {
      local timeStart = {}
      local timeFinish = {}

      if (response.error != 0)
        return

      (response?.list ?? [])
        .each(function (x) {
          nearestTime(x, "enable_queue", timeStart)
          nearestTime(x, "disable_queue", timeFinish)
        })

      foreach (queueId, timestamp in timeStart) {
        if (timeFinish[queueId] < timestamp)
          timeStart[queueId] = 0
      }
      eventStartTime.set(timeStart)
      isMMScheduleProcessed = true
    }, {appId = get_app_id()})
}

let requestNewSchedule = debounce(function() {
  isMMScheduleProcessed = false
  timeUntilStart()
}, 0, MAX_DELAY_FOR_MASSIVE_REQUEST_SEC)

hasBaseEvent.subscribe(@(_) timeUntilStart())

matching_listen_notify("enlmm.notify_schedule_list_changed")
eventbus_subscribe("enlmm.notify_schedule_list_changed", @(_) requestNewSchedule())

let selectEvent = @(eventId) selEventIdByPlayer.set(eventId)

function checkEventModesAccess() {
  if (allEventsToShow.get().len() == 0 && !hasCustomRooms.get())
    isEventModesOpened.set(false)
}

function openEventModes(eventId = "") {
  if (allEventsToShow.get().len() == 0) {
    openCustomGameMode()
  }
  else {
    openEventsGameMode()
    if (eventId != "")
      selectEvent(eventId)
  }
}

return {
  activeEvents
  inactiveEventsToShow
  allEventsToShow
  promotedEvent
  isEventModesOpened
  isCustomRoomsMode
  hasCustomRooms
  customRoomsModeSaved
  selEvent
  selLbMode
  selectEvent
  openEventModes
  checkEventModesAccess
  openCustomGameMode
  openEventsGameMode
  selEventEndTime
  eventCustomSquads
  eventsSquadList
  eventsArmiesList
  eventCurArmyId
  hasBaseEvent
  eventCustomProfile
  curTab
  eventStartTime
  isEventPlayable
}
