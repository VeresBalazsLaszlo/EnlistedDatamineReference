from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/userstats/unlocksState.nut" import unlocksSorted, unlockProgress, emptyProgress
from "%ui/userstats/userstat.nut" import userstatStats, userstatLbStats
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%dngscripts/platform.nut" import isPlatformRelevant
from "%ui/ui_library.nut" import *

let debugOverrideTime = mkWatched(persist, "debugOverrideTime", null)

let getNextUnlock = @(unlockName, unlocks)
  unlocks.findvalue(@(u) (u?.requirement ?? "") == unlockName)

let unlocksData = Computed(function() {
  let events = {}
  let forcedUrl = []

  foreach (unlock in unlocksSorted.get()) {
    local {
      force_open_url = "", promote_squads = null, promote_campaign = null, platforms = null,
      event_unlock = false, event_group = null
    } = unlock?.meta

    if (platforms != null
        && !isPlatformRelevant(typeof platforms == "array" ? platforms : [platforms]))
      continue

    if (promote_campaign != null) {
      let promoCamp = typeof promote_campaign == "array" ? promote_campaign : [promote_campaign]
      if (promoCamp.len() != 0 && !promoCamp.contains(COMMON_CAMPAIGN))
        continue
    }

    if (force_open_url != "") {
      let title = unlock?.localization.name ?? ""
      forcedUrl.append({
        url = force_open_url
        image = unlock?.meta.image
        title = title != "" ? title : loc("eventWidget/specialOffer")
      })
      continue
    }

    if (event_unlock && event_group == null)
      event_group = "events" 
    if (event_group == null)
      continue

    local event = events?[event_group]
    if (event == null) {
      let stat = userstatStats.get()?.stats[event_group] ?? userstatLbStats.get()?.stats[event_group]
      event = {
        group = event_group
        start = debugOverrideTime.get()?.start ?? stat?["$startedAt"] ?? 0
        end = debugOverrideTime.get()?.end ?? stat?["$endsAt"] ?? 0
        unlocks = []
        squads = []
      }
      events[event_group] <- event
    }
    if (promote_squads != null)
      event.squads.extend(typeof promote_squads == "array"
        ? promote_squads
        : [promote_squads])
    else
      event.unlocks.append(unlock)
  }

  let progress = unlockProgress.get()
  foreach (event in events) {
    let { unlocks } = event
    let startUnlocks = unlocks.filter(@(u) (u?.requirement ?? "") == "")
      .sort(@(a,b) a?.meta.taskListPlace == null ? 1
        : b?.meta.taskListPlace == null ? -1
        : a.meta.taskListPlace <=> b.meta.taskListPlace)
    let targetUnlocks = []
    foreach (unlock in startUnlocks) {
      local step = 1
      targetUnlocks.append(unlock.__merge({ step }, progress?[unlock.name] ?? emptyProgress))
      local nextUnlock = getNextUnlock(unlock.name, unlocks)
      while (nextUnlock != null) {
        step++
        targetUnlocks.append(nextUnlock.__merge({ step }, progress?[nextUnlock.name] ?? emptyProgress))
        nextUnlock = getNextUnlock(nextUnlock.name, unlocks)
      }
    }
    local totalSteps = 1
    for (local i = targetUnlocks.len() - 1; i >= 0; i--) {
      let { step } = targetUnlocks[i]
      totalSteps = max(totalSteps, step)
      targetUnlocks[i].totalSteps <- totalSteps
      if (step == 1)
        totalSteps = 1
    }
    event.unlocks <- targetUnlocks
  }

  return {
    events
    forcedUrl
  }
})

let showNotActiveTaskMsgbox = @()
  showMsgbox(loc("unlocks/eventUnlockNotActiveYet"))

console_register_command(@() debugOverrideTime.set(null), "meta.eventPromoTimeReset")
console_register_command(@(start, end) debugOverrideTime.set({ start, end }), "meta.eventPromoSetTime")

return {
  eventForcedUrl = Computed(@() unlocksData.get().forcedUrl)
  specialEvents = Computed(@() unlocksData.get().events)
  showNotActiveTaskMsgbox
}
